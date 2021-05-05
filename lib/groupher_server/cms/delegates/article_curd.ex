defmodule GroupherServer.CMS.Delegate.ArticleCURD do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false

  import GroupherServer.CMS.Utils.Matcher2

  import GroupherServer.CMS.Utils.Matcher, only: [match_action: 2, dynamic_where: 2]
  import Helper.Utils, only: [done: 1, pick_by: 2, integerfy: 1]
  import Helper.ErrorCode
  import ShortMaps

  alias GroupherServer.{Accounts, CMS, Delivery, Email, Repo, Statistics}

  alias Accounts.User
  alias CMS.{Author, Community, PinnedArticle, Embeds, Delegate, Tag}

  alias Delegate.ArticleOperation
  alias Helper.{Later, ORM, QueryBuilder}

  alias Ecto.Multi

  @default_article_meta Embeds.ArticleMeta.default_meta()

  @doc """
  login user read cms content by add views count and viewer record
  """
  def read_content(thread, id, %User{id: user_id}) do
    condition = %{user_id: user_id} |> Map.merge(content_id(thread, id))

    with {:ok, action} <- match_action(thread, :self),
         {:ok, _viewer} <- action.viewer |> ORM.findby_or_insert(condition, condition) do
      action.target |> ORM.read(id, inc: :views)
    end
  end

  @doc """
  get paged post / job ...
  """
  def paged_contents(queryable, filter, user) do
    queryable
    |> domain_filter_query(filter)
    |> community_with_flag_query(filter)
    |> read_state_query(filter, user)
    |> ORM.find_all(filter)
    |> add_pin_contents_ifneed(queryable, filter)
  end

  def paged_contents(queryable, filter) do
    queryable
    |> domain_filter_query(filter)
    |> community_with_flag_query(filter)
    |> ORM.find_all(filter)
    # TODO: if filter has when/sort/length/job... then don't
    |> add_pin_contents_ifneed(queryable, filter)
  end

  @doc """
  Creates a content(post/job ...), and set community.

  ## Examples

  iex> create_post(%{field: value})
  {:ok, %Post{}}

  iex> create_post(%{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def create_content(%Community{id: cid}, thread, attrs, %User{id: uid}) do
    with {:ok, author} <- ensure_author_exists(%User{id: uid}),
         {:ok, action} <- match_action(thread, :community),
         {:ok, community} <- ORM.find(Community, cid) do
      Multi.new()
      |> Multi.run(:create_content, fn _, _ ->
        do_create_content(action.target, attrs, author, community)
      end)
      |> Multi.run(:set_community, fn _, %{create_content: content} ->
        ArticleOperation.set_community(community, thread, content.id)
      end)
      |> Multi.run(:set_community_flag, fn _, %{create_content: content} ->
        exec_set_community_flag(community, content, action)
      end)
      |> Multi.run(:set_tag, fn _, %{create_content: content} ->
        exec_set_tag(thread, content.id, attrs)
      end)
      |> Multi.run(:mention_users, fn _, %{create_content: content} ->
        Delivery.mention_from_content(community.raw, thread, content, attrs, %User{id: uid})
        {:ok, :pass}
      end)
      |> Multi.run(:log_action, fn _, _ ->
        Statistics.log_publish_action(%User{id: uid})
      end)
      |> Repo.transaction()
      |> create_content_result()
    end
  end

  @doc """
  notify(email) admin about new content
  NOTE:  this method should NOT be pravite, because this method
  will be called outside this module
  """
  def notify_admin_new_content(%{id: id} = result) do
    target = result.__struct__
    preload = [:origial_community, author: :user]

    with {:ok, content} <- ORM.find(target, id, preload: preload) do
      info = %{
        id: content.id,
        title: content.title,
        digest: Map.get(content, :digest, content.title),
        author_name: content.author.user.nickname,
        community_raw: content.origial_community.raw,
        type:
          result.__struct__ |> to_string |> String.split(".") |> List.last() |> String.downcase()
      }

      Email.notify_admin(info, :new_content)
    end
  end

  @doc """
  update a content(post/job ...)
  """
  def update_content(content, args) do
    Multi.new()
    |> Multi.run(:update_content, fn _, _ ->
      ORM.update(content, args)
    end)
    |> Multi.run(:update_edit_status, fn _, %{update_content: update_content} ->
      ArticleOperation.update_edit_status(update_content)
    end)
    |> Multi.run(:update_tag, fn _, _ ->
      # TODO: move it to ArticleOperation module
      exec_update_tags(content, args)
    end)
    |> Repo.transaction()
    |> update_content_result()
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

  # filter community & untrash
  defp community_with_flag_query(queryable, filter, flag \\ %{}) do
    flag = %{trash: false} |> Map.merge(flag)
    # NOTE: this case judge is used for test case
    case filter |> Map.has_key?(:community) do
      true ->
        queryable
        |> join(:inner, [content], f in assoc(content, :community_flags))
        |> join(:inner, [content, f], c in assoc(f, :community))
        |> where([content, f, c], f.trash == ^flag.trash)
        |> where([content, f, c], c.raw == ^filter.community)

      false ->
        queryable
    end
  end

  defp domain_filter_query(CMS.Job = queryable, filter) do
    Enum.reduce(filter, queryable, fn
      {:salary, salary}, queryable ->
        queryable |> where([content], content.salary == ^salary)

      {:field, field}, queryable ->
        queryable |> where([content], content.field == ^field)

      {:finance, finance}, queryable ->
        queryable |> where([content], content.finance == ^finance)

      {:scale, scale}, queryable ->
        queryable |> where([content], content.scale == ^scale)

      {:exp, exp}, queryable ->
        if exp == "不限", do: queryable, else: queryable |> where([content], content.exp == ^exp)

      {:education, education}, queryable ->
        cond do
          education == "大专" ->
            queryable
            |> where([content], content.education == "大专" or content.education == "不限")

          education == "本科" ->
            queryable
            |> where([content], content.education != "不限")
            |> where([content], content.education != "大专")

          education == "硕士" ->
            queryable
            |> where([content], content.education != "不限")
            |> where([content], content.education != "大专")
            |> where([content], content.education != "本科")

          education == "不限" ->
            queryable

          true ->
            queryable |> where([content], content.education == ^education)
        end

      {_, _}, queryable ->
        queryable
    end)
  end

  defp domain_filter_query(CMS.Repo = queryable, filter) do
    Enum.reduce(filter, queryable, fn
      {:sort, :most_github_star}, queryable ->
        queryable |> order_by(desc: :star_count)

      {:sort, :most_github_fork}, queryable ->
        queryable |> order_by(desc: :fork_count)

      {:sort, :most_github_watch}, queryable ->
        queryable |> order_by(desc: :watch_count)

      {:sort, :most_github_pr}, queryable ->
        queryable |> order_by(desc: :prs_count)

      {:sort, :most_github_issue}, queryable ->
        queryable |> order_by(desc: :issues_count)

      {_, _}, queryable ->
        queryable
    end)
  end

  defp domain_filter_query(queryable, _filter), do: queryable

  # query if user has viewed before
  defp read_state_query(queryable, %{read: true} = _filter, user) do
    queryable
    |> join(:inner, [content, f, c], viewers in assoc(content, :viewers))
    |> where([content, f, c, viewers], viewers.user_id == ^user.id)
  end

  defp read_state_query(queryable, %{read: false} = _filter, _user) do
    queryable
  end

  defp read_state_query(queryable, _, _), do: queryable

  defp add_pin_contents_ifneed(contents, querable, %{community: _community} = filter) do
    with {:ok, _} <- should_add_pin?(filter),
         {:ok, info} <- match(querable),
         {:ok, normal_contents} <- contents,
         true <- Map.has_key?(filter, :community),
         true <- 1 == Map.get(normal_contents, :page_number) do
      {:ok, pined_content} =
        PinnedArticle
        |> join(:inner, [p], c in assoc(p, :community))
        |> join(:inner, [p], content in assoc(p, ^info.thread))
        |> where([p, c, content], c.raw == ^filter.community)
        |> select([p, c, content], content)
        # 10 pined contents per community/thread, at most
        |> ORM.paginater(%{page: 1, size: 10})
        |> done()

      concat_contents(pined_content, normal_contents)
    else
      _error ->
        contents
    end
  end

  defp add_pin_contents_ifneed(contents, _querable, _filter), do: contents

  # if filter contains like: tags, sort.., then don't add pin content
  defp should_add_pin?(%{page: 1, tag: :all, sort: :desc_inserted, read: :all} = filter) do
    filter
    |> Map.keys()
    |> Enum.reject(fn x -> x in [:community, :tag, :sort, :read, :page, :size] end)
    |> case do
      [] -> {:ok, :pass}
      _ -> {:error, :pass}
    end
  end

  defp should_add_pin?(_filter), do: {:error, :pass}

  defp concat_contents(%{total_count: 0}, normal_contents), do: {:ok, normal_contents}

  defp concat_contents(pined_content, normal_contents) do
    pind_entries =
      pined_content
      |> Map.get(:entries)
      |> Enum.map(&struct(&1, %{is_pinned: true}))

    normal_entries = normal_contents |> Map.get(:entries)

    # pind_count = pined_content |> Map.get(:total_count)
    normal_count = normal_contents |> Map.get(:total_count)

    # remote the pined content from normal_entries (if have)
    pind_ids = pick_by(pind_entries, :id)
    normal_entries = Enum.reject(normal_entries, &(&1.id in pind_ids))

    normal_contents
    |> Map.put(:entries, pind_entries ++ normal_entries)
    # those two are equals
    # |> Map.put(:total_count, pind_count + normal_count - pind_count)
    |> Map.put(:total_count, normal_count)
    |> done
  end

  defp create_content_result({:ok, %{create_content: result}}) do
    Later.exec({__MODULE__, :notify_admin_new_content, [result]})
    {:ok, result}
  end

  defp create_content_result({:error, :create_content, %Ecto.Changeset{} = result, _steps}) do
    {:error, result}
  end

  defp create_content_result({:error, :create_content, _result, _steps}) do
    {:error, [message: "create cms content author", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_community, _result, _steps}) do
    {:error, [message: "set community", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_community_flag, _result, _steps}) do
    {:error, [message: "set community flag", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_tag, result, _steps}) do
    {:error, result}
  end

  defp create_content_result({:error, :log_action, _result, _steps}) do
    {:error, [message: "log action", code: ecode(:create_fails)]}
  end

  defp update_content_result({:ok, %{update_edit_status: result}}), do: {:ok, result}
  defp update_content_result({:error, :update_content, result, _steps}), do: {:error, result}
  defp update_content_result({:error, :update_tag, result, _steps}), do: {:error, result}

  defp content_id(:post, id), do: %{post_id: id}
  defp content_id(:job, id), do: %{job_id: id}
  defp content_id(:repo, id), do: %{repo_id: id}

  #  for create content step in Multi.new
  defp do_create_content(target, attrs, %Author{id: aid}, %Community{id: cid}) do
    target
    |> struct()
    |> target.changeset(attrs)
    |> Ecto.Changeset.put_change(:author_id, aid)
    |> Ecto.Changeset.put_change(:origial_community_id, integerfy(cid))
    |> Ecto.Changeset.put_embed(:meta, @default_article_meta)
    |> Repo.insert()
  end

  defp exec_set_tag(thread, id, %{tags: tags}) do
    try do
      Enum.each(tags, fn tag ->
        {:ok, _} = ArticleOperation.set_tag(thread, %Tag{id: tag.id}, id)
      end)

      {:ok, "psss"}
    rescue
      _ -> {:error, [message: "set tag", code: ecode(:create_fails)]}
    end
  end

  defp exec_set_tag(_thread, _id, _attrs), do: {:ok, :pass}

  # TODO:  flag 逻辑似乎有问题
  defp exec_set_community_flag(%Community{} = community, content, %{flag: _flag}) do
    ArticleOperation.set_community_flags(community, content, %{
      trash: false
    })
  end

  defp exec_set_community_flag(_community, _content, _action) do
    {:ok, :pass}
  end

  # except Job, other content will just pass, should use set_tag function instead
  # defp exec_update_tags(_, _tags_ids), do: {:ok, :pass}

  defp exec_update_tags(_content, %{tags: tags_ids}) when tags_ids == [], do: {:ok, :pass}

  defp exec_update_tags(content, %{tags: tags_ids}) do
    with {:ok, content} <- ORM.find(content.__struct__, content.id, preload: :tags) do
      tags =
        Enum.reduce(tags_ids, [], fn t, acc ->
          {:ok, tag} = ORM.find(Tag, t.id)

          acc ++ [tag]
        end)

      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, tags)
      |> Repo.update()
    end
  end

  defp exec_update_tags(_content, _), do: {:ok, :pass}
end
