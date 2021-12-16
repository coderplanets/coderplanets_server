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
      module_to_atom: 1,
      get_config: 2,
      ensure: 2,
      module_to_upcase: 1,
      atom_values_to_upcase: 1
    ]

  import GroupherServer.CMS.Delegate.Helper, only: [mark_viewer_emotion_states: 2, thread_of: 1]
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.{Later, ORM, QueryBuilder, Converter}
  alias GroupherServer.{Accounts, CMS, Email, Repo, Statistics}

  alias Accounts.Model.User
  alias CMS.Model.{Author, Community, PinnedArticle, Embeds}
  alias CMS.Model.Repo, as: CMSRepo
  alias CMS.Constant

  alias CMS.Delegate.{
    ArticleCommunity,
    CommentCURD,
    ArticleTag,
    CommunityCURD,
    Document,
    Hooks
  }

  alias Ecto.Multi

  @active_period get_config(:article, :active_period_days)
  @archive_threshold get_config(:article, :archive_threshold)

  @default_emotions Embeds.ArticleEmotion.default_emotions()
  @default_article_meta Embeds.ArticleMeta.default_meta()
  @default_user_meta Accounts.Model.Embeds.UserMeta.default_meta()
  @remove_article_hint "The content does not comply with the community norms"

  @audit_legal Constant.pending(:legal)
  @audit_illegal Constant.pending(:illegal)
  @audit_failed Constant.pending(:audit_failed)

  @doc """
  read articles for un-logined user
  """
  def read_article(thread, id) do
    with {:ok, article} <- check_article_pending(thread, id) do
      do_read_article(article, thread)
    end
  end

  def read_article(thread, id, %User{id: user_id} = user) do
    with {:ok, article} <- check_article_pending(thread, id, user) do
      Multi.new()
      |> Multi.run(:normal_read, fn _, _ -> do_read_article(article, thread) end)
      |> Multi.run(:add_viewed_user, fn _, %{normal_read: article} ->
        update_viewed_user_list(article, user_id)
      end)
      |> Multi.run(:set_viewer_has_states, fn _, %{normal_read: article} ->
        article = Repo.preload(article, :original_community)
        article_meta = ensure(article.meta, @default_article_meta)

        viewer_has_states = %{
          viewer_has_collected: user_id in article_meta.collected_user_ids,
          viewer_has_upvoted: user_id in article_meta.upvoted_user_ids,
          viewer_has_reported: user_id in article_meta.reported_user_ids
        }

        article
        |> Map.merge(viewer_has_states)
        |> done
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  get paged articles
  """
  def paged_articles(thread, filter) do
    %{page: page, size: size} = filter
    flags = %{mark_delete: false, pending: :legal}

    with {:ok, info} <- match(thread) do
      info.model
      |> QueryBuilder.domain_query(filter)
      |> QueryBuilder.filter_pack(Map.merge(filter, flags))
      |> ORM.paginator(~m(page size)a)
      # |> ORM.cursor_paginator()
      |> add_pin_articles_ifneed(info.model, filter)
      |> done()
    end
  end

  def paged_articles(thread, filter, %User{} = user) do
    with {:ok, stateless_paged_articles} <- paged_articles(thread, filter) do
      stateless_paged_articles
      |> mark_viewer_emotion_states(user)
      |> mark_viewer_has_states(user)
      |> done()
    end
  end

  @doc "paged published articles for accounts"
  def paged_published_articles(thread, filter, user_id) do
    %{page: page, size: size} = filter

    with {:ok, info} <- match(thread),
         {:ok, user} <- ORM.find(User, user_id) do
      info.model
      |> join(:inner, [article], author in assoc(article, :author))
      |> where([article, author], author.user_id == ^user.id)
      |> select([article, author], article)
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginator(~m(page size)a)
      |> mark_viewer_emotion_states(user)
      |> mark_viewer_has_states(user)
      |> done()
    end
  end

  # get audit failed articles
  def paged_audit_failed_articles(thread, filter) do
    %{page: page, size: size} = filter
    flags = %{mark_delete: false, pending: :audit_failed}

    with {:ok, info} <- match(thread) do
      info.model
      |> QueryBuilder.filter_pack(Map.merge(filter, flags))
      |> ORM.paginator(~m(page size)a)
      |> done()
    end
  end

  @doc """
  archive articles based on thread
  called every day by scheuler job
  """
  def archive_articles(thread) do
    with {:ok, info} <- match(thread) do
      now = Timex.now()
      threshold = @archive_threshold[thread] || @archive_threshold[:default]
      archive_threshold = Timex.shift(now, threshold)

      info.model
      |> where([article], article.inserted_at < ^archive_threshold)
      |> Repo.update_all(set: [is_archived: true, archived_at: now])
      |> done()
    end
  end

  # 调用审核接口失败，等待队列定时处理
  def set_article_audit_failed(article, _audit_state) do
    ORM.update(article, %{pending: @audit_failed})
  end

  @doc """
  pending an article due to forbid words or spam talk
  """
  def set_article_illegal(thread, id, audit_state) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id) do
      set_article_illegal(article, audit_state)
    end
  end

  def set_article_illegal(article, audit_state) do
    # 1. set pending state
    # 2. set article meta
    # 3. set author meta
    Multi.new()
    |> Multi.run(:update_pending_state, fn _, _ ->
      ORM.update(article, %{pending: @audit_illegal})
    end)
    |> Multi.run(:update_article_meta, fn _, %{update_pending_state: article} ->
      legal_state = Map.take(audit_state, [:is_legal, :illegal_reason, :illegal_words])
      article_meta = ensure(article.meta, @default_article_meta)
      meta = Map.merge(article_meta, legal_state)

      ORM.update_meta(article, meta)
    end)
    |> Multi.run(:update_author_meta, fn _, _ ->
      article = Repo.preload(article, :author)
      illegal_articles = Map.get(audit_state, :illegal_articles, [])

      with {:ok, user} <- ORM.find(User, article.author.user_id) do
        user_meta = ensure(user.meta, @default_user_meta)
        illegal_articles = user_meta.illegal_articles ++ illegal_articles

        meta =
          Map.merge(user_meta, %{has_illegal_articles: true, illegal_articles: illegal_articles})

        ORM.update_meta(user, meta)
      end
    end)
    |> Repo.transaction()
    |> result()
  end

  def unset_article_illegal(thread, id, audit_state) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id) do
      unset_article_illegal(article, audit_state)
    end
  end

  def unset_article_illegal(article, audit_state) do
    Multi.new()
    |> Multi.run(:update_pending_state, fn _, _ ->
      ORM.update(article, %{pending: @audit_legal})
    end)
    |> Multi.run(:update_article_meta, fn _, %{update_pending_state: article} ->
      legal_state = Map.take(audit_state, [:is_legal, :illegal_reason, :illegal_words])
      article_meta = ensure(article.meta, @default_article_meta)
      meta = Map.merge(article_meta, legal_state)

      ORM.update_meta(article, meta)
    end)
    |> Multi.run(:update_author_meta, fn _, _ ->
      article = Repo.preload(article, :author)
      illegal_articles = Map.get(audit_state, :illegal_articles, [])

      with {:ok, user} <- ORM.find(User, article.author.user_id) do
        user_meta = ensure(user.meta, @default_user_meta)
        illegal_articles = user_meta.illegal_articles -- illegal_articles
        has_illegal_articles = not Enum.empty?(illegal_articles)

        meta =
          Map.merge(user_meta, %{
            has_illegal_articles: has_illegal_articles,
            illegal_articles: illegal_articles
          })

        ORM.update_meta(user, meta)
      end
    end)
    |> Repo.transaction()
    |> result()
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
    attrs = atom_values_to_upcase(attrs)

    with {:ok, author} <- ensure_author_exists(%User{id: uid}),
         {:ok, info} <- match(thread),
         {:ok, community} <- ORM.find(Community, cid) do
      Multi.new()
      |> Multi.run(:create_article, fn _, _ ->
        do_create_article(info.model, attrs, author, community)
      end)
      |> Multi.run(:create_document, fn _, %{create_article: article} ->
        Document.create(article, attrs)
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
      |> Multi.run(:after_hooks, fn _, %{create_article: article} ->
        Later.run({Hooks.Cite, :handle, [article]})
        Later.run({Hooks.Mention, :handle, [article]})
        Later.run({Hooks.Audition, :handle, [article]})
        Later.run({__MODULE__, :notify_admin_new_article, [article]})
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
  def update_article(%{is_archived: true}, _attrs),
    do: raise_error(:archived, "article is archived, can not be edit or delete")

  def update_article(article, attrs) do
    attrs = atom_values_to_upcase(attrs)

    Multi.new()
    |> Multi.run(:update_article, fn _, _ ->
      do_update_article(article, attrs)
    end)
    |> Multi.run(:update_document, fn _, %{update_article: update_article} ->
      Document.update(update_article, attrs)
    end)
    |> Multi.run(:update_comment_question_flag_if_need, fn _, %{update_article: update_article} ->
      # 如果帖子的类型变了，那么 update 所有的 flag
      case Map.has_key?(attrs, :is_question) do
        true -> CommentCURD.batch_update_question_flag(update_article)
        false -> {:ok, :pass}
      end
    end)
    |> Multi.run(:update_edit_status, fn _, %{update_article: update_article} ->
      ArticleCommunity.update_edit_status(update_article)
    end)
    |> Multi.run(:after_hooks, fn _, %{update_article: update_article} ->
      Later.run({Hooks.Cite, :handle, [update_article]})
      Later.run({Hooks.Mention, :handle, [update_article]})
      Later.run({Hooks.Audition, :handle, [update_article]})
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
    active_period_days = @active_period[thread] || @active_period[:default]

    inserted_at = article.inserted_at
    active_threshold = Timex.shift(Timex.now(), days: -active_period_days)

    :gt == DateTime.compare(inserted_at, active_threshold)
  end

  @doc """
  mark delete falst for an anticle
  """
  def mark_delete_article(thread, id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id, preload: :communities),
         false <- article.is_archived do
      Multi.new()
      |> Multi.run(:update_article, fn _, _ ->
        ORM.update(article, %{mark_delete: true})
      end)
      |> Multi.run(:update_community_article_count, fn _, _ ->
        CommunityCURD.update_community_count_field(article.communities, thread)
      end)
      |> Repo.transaction()
      |> result()
    else
      true -> raise_error(:archived, "article is archived, can not be edit or delete")
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

  @doc """
  remove article forever
  """
  def delete_article(article, reason \\ @remove_article_hint) do
    article = Repo.preload(article, [:communities, [author: :user]])
    {:ok, thread} = thread_of(article)

    Multi.new()
    |> Multi.run(:delete_article, fn _, _ ->
      article |> ORM.delete()
    end)
    |> Multi.run(:update_community_article_count, fn _, _ ->
      CommunityCURD.update_community_count_field(article.communities, thread)
    end)
    |> Multi.run(:update_user_published_meta, fn _, _ ->
      Accounts.update_published_states(article.author.user.id, thread)
    end)
    |> Multi.run(:delete_document, fn _, _ ->
      Document.remove(thread, article.id)
      # for those history & test setup case
      {:ok, :pass}
    end)
    # TODO: notify author
    |> Repo.transaction()
    |> result()
  end

  @spec ensure_author_exists(User.t()) :: {:ok, User.t()}
  def ensure_author_exists(%User{} = user) do
    # unique_constraint: avoid race conditions, make sure user_id unique
    # foreign_key_constraint: check foreign key: user_id exsit or not
    # see alos no_assoc_constraint in https://hexdocs.pm/ecto/Ecto.Changeset.html
    case ORM.find_by(Author, user_id: user.id) do
      {:ok, author} ->
        {:ok, author}

      {:error, _} ->
        %Author{user_id: user.id}
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.unique_constraint(:user_id)
        |> Ecto.Changeset.foreign_key_constraint(:user_id)
        |> Repo.insert()
    end

    # %Author{user_id: user.id}
    # |> Ecto.Changeset.change()
    # |> Ecto.Changeset.unique_constraint(:user_id)
    # |> Ecto.Changeset.foreign_key_constraint(:user_id)
    # |> Repo.insert()
    # |> handle_existing_author()
  end

  # defp handle_existing_author({:ok, author}), do: {:ok, author}

  # defp handle_existing_author({:error, %Ecto.Changeset{changes: %{user_id: user_id}}}) do
  #   ORM.find_by(Author, user_id: user_id) |> IO.inspect(label: "after f2")
  # end

  # defp handle_existing_author({:error, changeset}) do
  #   ORM.find_by(Author, user_id: changeset.data.user_id)
  # end

  defp do_read_article(article, thread) do
    Multi.new()
    |> Multi.run(:inc_views, fn _, _ -> ORM.read(article, inc: :views) end)
    |> Multi.run(:load_html, fn _, %{inc_views: article} ->
      article |> Repo.preload(:document) |> done
    end)
    |> Multi.run(:update_article_meta, fn _, %{load_html: article} ->
      article_meta = ensure(article.meta, @default_article_meta)
      meta = Map.merge(article_meta, %{can_undo_sink: in_active_period?(thread, article)})

      ORM.update_meta(article, meta)
    end)
    |> Repo.transaction()
    |> result()
  end

  # pending article can be seen is viewer is author
  defp check_article_pending(thread, id, %User{} = user) when is_atom(thread) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id, preload: :author) do
      check_article_pending(article, user)
    end
  end

  defp check_article_pending(%{pending: @audit_legal} = article, _) do
    {:ok, article}
  end

  defp check_article_pending(%{pending: @audit_failed} = article, _) do
    {:ok, article}
  end

  defp check_article_pending(%{pending: @audit_illegal} = article, %User{id: user_id}) do
    case article.author.user_id == user_id do
      true -> {:ok, article}
      false -> raise_error(:pending, "this article is under audition")
    end
  end

  # pending article should not be seen
  defp check_article_pending(thread, id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id) do
      check_article_pending(article)
    end
  end

  defp check_article_pending(%{pending: @audit_illegal}) do
    raise_error(:pending, "this article is under audition")
  end

  defp check_article_pending(article), do: {:ok, article}

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
  defp do_create_article(model, %{body: _body} = attrs, %Author{id: author_id}, %Community{
         id: community_id
       }) do
    meta = @default_article_meta |> Map.merge(%{thread: module_to_upcase(model)})

    with {:ok, attrs} <- add_digest_attrs(attrs) do
      model.__struct__
      |> model.changeset(attrs)
      |> Ecto.Changeset.put_change(:emotions, @default_emotions)
      |> Ecto.Changeset.put_change(:author_id, author_id)
      |> Ecto.Changeset.put_change(:original_community_id, community_id)
      |> Ecto.Changeset.put_embed(:meta, meta)
      |> Repo.insert()
    end
  end

  # Github Repo 没有传统的 body, 需要特殊处理
  # 赋值一个空的 body, 后续在 document 中处理
  # 注意：digest 那里也要特殊处理
  defp do_create_article(CMSRepo, attrs, author, community) do
    body = Map.get(attrs, :body, Converter.Article.default_rich_text())
    attrs = Map.put(attrs, :body, body)

    do_create_article(CMSRepo, attrs, author, community)
  end

  defp do_update_article(article, %{body: _} = attrs) do
    with {:ok, attrs} <- add_digest_attrs(attrs) do
      ORM.update(article, attrs)
    end
  end

  defp do_update_article(article, attrs), do: ORM.update(article, attrs)

  # is update or create article with body field, parsed and extand it into attrs
  defp add_digest_attrs(%{body: body} = attrs) when not is_nil(body) do
    with {:ok, parsed} <- Converter.Article.parse_body(body),
         {:ok, digest} <- Converter.Article.parse_digest(parsed.body_map) do
      attrs
      |> Map.merge(%{digest: digest})
      |> done
    end
  end

  defp add_digest_attrs(attrs), do: attrs

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
        meta = meta |> Map.merge(%{viewed_user_ids: new_ids})
        ORM.update_meta(article, meta)

      false ->
        {:ok, :pass}
    end
  end

  # create done
  defp result({:ok, %{set_active_at_timestamp: result}}) do
    {:ok, result}
  end

  defp result({:ok, %{update_edit_status: result}}), do: {:ok, result}
  defp result({:ok, %{update_article: result}}), do: {:ok, result}
  defp result({:ok, %{delete_article: result}}), do: {:ok, result}
  # NOTE:  for read article, order is import
  defp result({:ok, %{set_viewer_has_states: result}}), do: result |> done()
  defp result({:ok, %{update_article_meta: result}}), do: {:ok, result}

  defp result({:error, :create_article, _result, _steps}) do
    {:error, [message: "create article", code: ecode(:create_fails)]}
  end

  defp result({:error, :update_article, _result, _steps}) do
    {:error, [message: "update article", code: ecode(:update_fails)]}
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
