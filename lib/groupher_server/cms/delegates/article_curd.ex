defmodule GroupherServer.CMS.Delegate.ArticleCURD do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false

  import GroupherServer.CMS.Helper.Matcher

  import Helper.Utils,
    only: [
      done: 1,
      pick_by: 2,
      integerfy: 1,
      strip_struct: 1,
      module_to_atom: 1,
      get_config: 2,
      ensure: 2
    ]

  import GroupherServer.CMS.Delegate.Helper, only: [mark_viewer_emotion_states: 2]
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.{Later, ORM, QueryBuilder, Converter}
  alias GroupherServer.{Accounts, CMS, Delivery, Email, Repo, Statistics}

  alias Accounts.Model.User
  alias CMS.Model.{Author, Community, PinnedArticle, Embeds}
  alias CMS.Delegate.{ArticleCommunity, ArticleComment, ArticleTag, CommunityCURD}

  alias Ecto.Multi

  @active_period get_config(:article, :active_period_days)
  @default_emotions Embeds.ArticleEmotion.default_emotions()
  @default_article_meta Embeds.ArticleMeta.default_meta()

  content = """
  {
    "time": 2018,
    "blocks": [],
    "version": "2.22.0"
  }
  """

  @doc """
  read articles for un-logined user
  """
  def read_article(thread, id) do
    with {:ok, info} <- match(thread) do
      Multi.new()
      |> Multi.run(:inc_views, fn _, _ -> ORM.read(info.model, id, inc: :views) end)
      |> Multi.run(:update_article_meta, fn _, %{inc_views: article} ->
        article_meta = ensure(article.meta, @default_article_meta)
        meta = Map.merge(article_meta, %{can_undo_sink: in_active_period?(thread, article)})

        ORM.update_meta(article, meta)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  read articles for logined user
  """
  def read_article(thread, id, %User{id: user_id}) do
    with {:ok, info} <- match(thread) do
      Multi.new()
      |> Multi.run(:inc_views, fn _, _ -> ORM.read(info.model, id, inc: :views) end)
      |> Multi.run(:update_article_meta, fn _, %{inc_views: article} ->
        article_meta = ensure(article.meta, @default_article_meta)
        meta = Map.merge(article_meta, %{can_undo_sink: in_active_period?(thread, article)})

        ORM.update_meta(article, meta)
      end)
      |> Multi.run(:add_viewed_user, fn _, %{inc_views: article} ->
        update_viewed_user_list(article, user_id)
      end)
      |> Multi.run(:set_viewer_has_states, fn _, %{inc_views: article} ->
        article_meta = if is_nil(article.meta), do: @default_article_meta, else: article.meta

        viewer_has_states = %{
          viewer_has_collected: user_id in article_meta.collected_user_ids,
          viewer_has_upvoted: user_id in article_meta.upvoted_user_ids,
          viewer_has_reported: user_id in article_meta.reported_user_ids
        }

        {:ok, Map.merge(article, viewer_has_states)}
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def paged_articles(thread, filter) do
    %{page: page, size: size} = filter

    with {:ok, info} <- match(thread) do
      info.model
      |> QueryBuilder.domain_query(filter)
      |> QueryBuilder.filter_pack(Map.merge(filter, %{mark_delete: false}))
      |> ORM.paginater(~m(page size)a)
      |> add_pin_articles_ifneed(info.model, filter)
      |> done()
    end
  end

  def paged_articles(thread, filter, %User{} = user) do
    %{page: page, size: size} = filter

    with {:ok, info} <- match(thread) do
      info.model
      |> QueryBuilder.domain_query(filter)
      |> QueryBuilder.filter_pack(Map.merge(filter, %{mark_delete: false}))
      |> ORM.paginater(~m(page size)a)
      |> add_pin_articles_ifneed(info.model, filter)
      |> mark_viewer_emotion_states(user)
      |> mark_viewer_has_states(user)
      |> done()
    end
  end

  defp mark_viewer_has_states(%{entries: []} = articles, _), do: articles

  defp mark_viewer_has_states(%{entries: entries} = articles, user) do
    entries = Enum.map(entries, &Map.merge(&1, do_mark_viewer_has_states(&1.meta, user)))
    Map.merge(articles, %{entries: entries})
  end

  defp mark_viewer_has_states({:error, reason}, _), do: {:error, reason}

  defp do_mark_viewer_has_states(nil, _) do
    %{
      viewer_has_collected: false,
      viewer_has_upvoted: false,
      viewer_has_viewed: false,
      viewer_has_reported: false
    }
  end

  defp do_mark_viewer_has_states(meta, %User{id: user_id}) do
    # TODO: 根据是否付费进一步判断
    # user_is_member = true
    %{
      viewer_has_collected: Enum.member?(meta.collected_user_ids, user_id),
      viewer_has_upvoted: Enum.member?(meta.upvoted_user_ids, user_id),
      viewer_has_viewed: Enum.member?(meta.viewed_user_ids, user_id),
      viewer_has_reported: Enum.member?(meta.reported_user_ids, user_id)
    }
  end

  @doc """
  Creates a article

  ## Examples

  iex> create_article(community, :post, %{title: ...}, user)
  {:ok, %Post{}}
  """
  def create_article(%Community{id: cid}, thread, attrs, %User{id: uid}) do
    with {:ok, author} <- ensure_author_exists(%User{id: uid}),
         {:ok, info} <- match(thread),
         {:ok, community} <- ORM.find(Community, cid) do
      Multi.new()
      |> Multi.run(:create_article, fn _, _ ->
        do_create_article(info.model, attrs, author, community)
      end)
      |> Multi.run(:mirror_article, fn _, %{create_article: article} ->
        ArticleCommunity.mirror_article(thread, article.id, community.id)
      end)
      |> Multi.run(:set_article_tags, fn _, %{create_article: article} ->
        ArticleTag.set_article_tags(community, thread, article, attrs)
      end)
      |> Multi.run(:set_active_at_timestamp, fn _, %{create_article: article} ->
        ORM.update(article, %{active_at: article.inserted_at})
      end)
      |> Multi.run(:update_community_article_count, fn _, _ ->
        CommunityCURD.update_community_count_field(community, thread)
      end)
      |> Multi.run(:update_user_published_meta, fn _, _ ->
        Accounts.update_published_states(uid, thread)
      end)
      # TODO: run mini tasks
      |> Multi.run(:mention_users, fn _, %{create_article: article} ->
        # article.body |> Jason.decode!() |> 各种小 task
        Delivery.mention_from_content(community.raw, thread, article, attrs, %User{id: uid})
        {:ok, :pass}
      end)
      |> Multi.run(:log_action, fn _, _ ->
        Statistics.log_publish_action(%User{id: uid})
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  notify(email) admin about new article
  NOTE:  this method should NOT be pravite, because this method
  will be called outside this module
  """
  def notify_admin_new_article(%{id: id} = result) do
    target = result.__struct__
    preload = [:original_community, author: :user]

    with {:ok, article} <- ORM.find(target, id, preload: preload) do
      info = %{
        id: article.id,
        title: article.title,
        digest: Map.get(article, :digest, article.title),
        author_name: article.author.user.nickname,
        community_raw: article.original_community.raw,
        type:
          result.__struct__ |> to_string |> String.split(".") |> List.last() |> String.downcase()
      }

      Email.notify_admin(info, :new_article)
    end
  end

  @doc """
  update a article(post/job ...)
  """
  def update_article(article, args) do
    Multi.new()
    |> Multi.run(:update_article, fn _, _ -> ORM.update(article, args) end)
    |> Multi.run(:update_comment_question_flag_if_need, fn _, %{update_article: update_article} ->
      # 如果帖子的类型变了，那么 update 所有的 flag
      case Map.has_key?(args, :is_question) do
        true -> ArticleComment.batch_update_question_flag(update_article)
        false -> {:ok, :pass}
      end
    end)
    |> Multi.run(:update_edit_status, fn _, %{update_article: update_article} ->
      ArticleCommunity.update_edit_status(update_article)
    end)
    |> Repo.transaction()
    |> result()
  end

  @doc """
  update active at timestamp of an article
  """
  def update_active_timestamp(thread, article) do
    # @article_active_period
    # 1. 超过时限不更新
    # 2. 已经沉默的不更新, is_sinked
    with true <- in_active_period?(thread, article) do
      ORM.update(article, %{active_at: DateTime.utc_now()})
    else
      _ -> {:ok, :pass}
    end
  end

  @doc """
  sink article
  """
  def sink_article(thread, id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id) do
      meta = Map.merge(article.meta, %{is_sinked: true, last_active_at: article.active_at})
      ORM.update_meta(article, meta, changes: %{active_at: article.inserted_at})
    end
  end

  @doc """
  undo sink article
  """
  def undo_sink_article(thread, id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id),
         true <- in_active_period?(thread, article) do
      meta = Map.merge(article.meta, %{is_sinked: false})
      ORM.update_meta(article, meta, changes: %{active_at: meta.last_active_at})
    else
      false -> raise_error(:undo_sink_old_article, "can not undo sink old article")
    end
  end

  # check is an article's active_at is in active period
  defp in_active_period?(thread, article) do
    active_period_days = Map.get(@active_period, thread)

    inserted_at = article.inserted_at
    active_threshold = Timex.shift(Timex.now(), days: -active_period_days)

    :gt == DateTime.compare(inserted_at, active_threshold)
  end

  @doc """
  mark delete falst for an anticle
  """
  def mark_delete_article(thread, id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id, preload: :communities) do
      Multi.new()
      |> Multi.run(:update_article, fn _, _ ->
        ORM.update(article, %{mark_delete: true})
      end)
      |> Multi.run(:update_community_article_count, fn _, _ ->
        CommunityCURD.update_community_count_field(article.communities, thread)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  undo mark delete falst for an anticle
  """
  def undo_mark_delete_article(thread, id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id, preload: :communities) do
      Multi.new()
      |> Multi.run(:update_article, fn _, _ ->
        ORM.update(article, %{mark_delete: false})
      end)
      |> Multi.run(:update_community_article_count, fn _, _ ->
        CommunityCURD.update_community_count_field(article.communities, thread)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @spec ensure_author_exists(User.t()) :: {:ok, User.t()}
  def ensure_author_exists(%User{} = user) do
    # unique_constraint: avoid race conditions, make sure user_id unique
    # foreign_key_constraint: check foreign key: user_id exsit or not
    # see alos no_assoc_constraint in https://hexdocs.pm/ecto/Ecto.Changeset.html
    %Author{user_id: user.id}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.unique_constraint(:user_id)
    |> Ecto.Changeset.foreign_key_constraint(:user_id)
    |> Repo.insert()
    |> handle_existing_author()
  end

  defp handle_existing_author({:ok, author}), do: {:ok, author}

  defp handle_existing_author({:error, changeset}) do
    ORM.find_by(Author, user_id: changeset.data.user_id)
  end

  defp add_pin_articles_ifneed(articles, querable, %{community: community} = filter) do
    thread = module_to_atom(querable)

    with true <- should_add_pin?(filter),
         true <- 1 == Map.get(articles, :page_number),
         {:ok, pinned_articles} <-
           PinnedArticle
           |> join(:inner, [p], c in assoc(p, :community))
           |> join(:inner, [p], article in assoc(p, ^thread))
           |> where([p, c, article], c.raw == ^community)
           |> select([p, c, article], article)
           # 10 pinned articles per community/thread, at most
           |> ORM.find_all(%{page: 1, size: 10}) do
      concat_articles(pinned_articles, articles)
    else
      _error -> articles
    end
  end

  defp add_pin_articles_ifneed(articles, _querable, _filter), do: articles

  # if filter contains like: tags, sort.., then don't add pin article
  defp should_add_pin?(%{page: 1, sort: :desc_active} = filter) do
    skip_pinned_fields = [:article_tag, :article_tags]

    not Enum.any?(Map.keys(filter), &(&1 in skip_pinned_fields))
  end

  defp should_add_pin?(_filter), do: false

  defp concat_articles(%{total_count: 0}, non_pinned_articles), do: non_pinned_articles

  defp concat_articles(pinned_articles, non_pinned_articles) do
    pinned_entries =
      pinned_articles
      |> Map.get(:entries)
      |> Enum.map(&struct(&1, %{is_pinned: true}))

    normal_entries = non_pinned_articles |> Map.get(:entries)

    normal_count = non_pinned_articles |> Map.get(:total_count)

    # remote the pinned article from normal_entries (if have)
    pind_ids = pick_by(pinned_entries, :id)
    normal_entries = Enum.reject(normal_entries, &(&1.id in pind_ids))

    non_pinned_articles
    |> Map.put(:entries, pinned_entries ++ normal_entries)
    # those two are equals
    # |> Map.put(:total_count, pind_count + normal_count - pind_count)
    |> Map.put(:total_count, normal_count)
  end

  #  for create artilce step in Multi.new
  defp do_create_article(target, attrs, %Author{id: aid}, %Community{id: cid}) do
    # special article like Repo do not have :body, assign it with default "{}"
    default_rich_text = Converter.Article.default_rich_text()
    body = Map.get(attrs, :body, default_rich_text)

    with {:ok, parsed} <- Converter.Article.parse_body(body),
         {:ok, digest} <- Converter.Article.parse_digest(parsed.body_map) do
      attrs =
        attrs
        |> Map.merge(Map.take(parsed, [:body, :body_html]))
        |> Map.merge(%{digest: digest})

      target
      |> struct()
      |> target.changeset(attrs)
      |> Ecto.Changeset.put_change(:emotions, @default_emotions)
      |> Ecto.Changeset.put_change(:author_id, aid)
      |> Ecto.Changeset.put_change(:original_community_id, integerfy(cid))
      |> Ecto.Changeset.put_embed(:meta, @default_article_meta)
      |> Repo.insert()
    end
  end

  # except Job, other article will just pass, should use set_article_tags function instead
  # defp exec_update_tags(_, _tags_ids), do: {:ok, :pass}

  defp update_viewed_user_list(%{meta: nil} = article, user_id) do
    new_ids = Enum.uniq([user_id] ++ @default_article_meta.viewed_user_ids)
    meta = @default_article_meta |> Map.merge(%{viewed_user_ids: new_ids})

    ORM.update_meta(article, meta)
  end

  defp update_viewed_user_list(%{meta: meta} = article, user_id) do
    user_not_viewed = not Enum.member?(meta.viewed_user_ids, user_id)

    case Enum.empty?(meta.viewed_user_ids) or user_not_viewed do
      true ->
        new_ids = Enum.uniq([user_id] ++ meta.viewed_user_ids)
        meta = meta |> Map.merge(%{viewed_user_ids: new_ids}) |> strip_struct
        ORM.update_meta(article, meta)

      false ->
        {:ok, :pass}
    end
  end

  # create done
  defp result({:ok, %{set_active_at_timestamp: result}}) do
    Later.exec({__MODULE__, :notify_admin_new_article, [result]})
    {:ok, result}
  end

  defp result({:ok, %{update_edit_status: result}}), do: {:ok, result}
  defp result({:ok, %{update_article: result}}), do: {:ok, result}
  defp result({:ok, %{set_viewer_has_states: result}}), do: result |> done()
  defp result({:ok, %{update_article_meta: result}}), do: {:ok, result}

  defp result({:error, :create_article, _result, _steps}) do
    {:error, [message: "create article", code: ecode(:create_fails)]}
  end

  defp result({:error, :mirror_article, _result, _steps}) do
    {:error, [message: "set community", code: ecode(:create_fails)]}
  end

  defp result({:error, :set_community_flag, _result, _steps}) do
    {:error, [message: "set community flag", code: ecode(:create_fails)]}
  end

  defp result({:error, :log_action, _result, _steps}) do
    {:error, [message: "log action", code: ecode(:create_fails)]}
  end

  defp result({:error, _, result, _steps}), do: {:error, result}
end
