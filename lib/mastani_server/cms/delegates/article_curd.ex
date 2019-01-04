defmodule MastaniServer.CMS.Delegate.ArticleCURD do
  @moduledoc """
  CURD operation on post/job/video ...
  """
  import Ecto.Query, warn: false
  import MastaniServer.CMS.Utils.Matcher
  import Helper.Utils, only: [done: 1, pick_by: 2]
  import Helper.ErrorCode
  import ShortMaps

  alias MastaniServer.Repo

  alias MastaniServer.Accounts.User
  alias MastaniServer.{CMS, Delivery, Statistics}

  alias CMS.Delegate.ArticleOperation
  alias Helper.{ORM, QueryBuilder}

  alias CMS.{Author, Community, Tag, Topic}
  alias Ecto.Multi

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
    |> community_with_flag_query(filter)
    |> read_state_query(filter, user)
    |> ORM.find_all(filter)
    |> add_pin_contents_ifneed(queryable, filter)
  end

  def paged_contents(queryable, filter) do
    queryable
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
  def create_content(
        %Community{id: community_id},
        thread,
        attrs,
        %User{id: user_id}
      ) do
    with {:ok, author} <- ensure_author_exists(%User{id: user_id}),
         {:ok, action} <- match_action(thread, :community),
         {:ok, community} <- ORM.find(Community, community_id) do
      Multi.new()
      |> Multi.run(:add_content_author, fn _, _ ->
        action.target
        |> struct()
        |> action.target.changeset(attrs)
        |> Ecto.Changeset.put_change(:author_id, author.id)
        |> Repo.insert()
      end)
      |> Multi.run(:set_community, fn _, %{add_content_author: content} ->
        ArticleOperation.set_community(community, thread, content.id)
      end)
      |> Multi.run(:set_topic, fn _, %{add_content_author: content} ->
        topic_title =
          case attrs |> Map.has_key?(:topic) do
            true -> attrs.topic
            false -> "posts"
          end

        ArticleOperation.set_topic(%Topic{title: topic_title}, thread, content.id)
      end)
      |> Multi.run(:set_community_flag, fn _, %{add_content_author: content} ->
        # TODO: remove this judge, as content should have a flag
        case action |> Map.has_key?(:flag) do
          true ->
            ArticleOperation.set_community_flags(content, community.id, %{
              trash: false
            })

          false ->
            {:ok, :pass}
        end
      end)
      |> Multi.run(:set_tag, fn _, %{add_content_author: content} ->
        case attrs |> Map.has_key?(:tags) do
          true -> set_tags(community, thread, content.id, attrs.tags)
          false -> {:ok, :pass}
        end
      end)
      |> Multi.run(:mention_users, fn _, %{add_content_author: content} ->
        Delivery.mention_from_content(thread, content, attrs, %User{id: user_id})
        {:ok, :pass}
      end)
      |> Multi.run(:log_action, fn _, _ ->
        Statistics.log_publish_action(%User{id: user_id})
      end)
      |> Repo.transaction()
      |> create_content_result()
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
    |> Multi.run(:update_tag, fn _, _ ->
      update_tags(content, args.tags)
    end)
    |> Repo.transaction()
    |> update_content_result()
  end

  @doc """
  get CMS contents
  post's favorites/stars/comments ...
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """
  def reaction_users(thread, react, id, %{page: page, size: size} = filters) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, where} <- dynamic_where(thread, id) do
      # common_filter(action.reactor)
      action.reactor
      |> where(^where)
      |> QueryBuilder.load_inner_users(filters)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

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

  # query if user has viewed before
  defp read_state_query(queryable, %{read: read} = filter, user) do
    cond do
      read == true ->
        queryable
        |> join(:inner, [content, f, c], viewers in assoc(content, :viewers))
        |> where([content, f, c, viewers], viewers.user_id == ^user.id)

      read == false ->
        # hello = ORM.find_all(CMS.PostViewer, %{page: 1, size: 10})
        # IO.inspect hello, label: "hello"

        # queryable
        # |> join(:left, [content, f, c], viewers in assoc(content, :viewers))
        # |> where([content, f, c, viewers], viewers.user_id != ^user.id)
        # |> where([content, f, c, viewers], content.id != viewers.post_id)
        # |> IO.inspect(label: "query")
        queryable

      true ->
        queryable
    end
  end

  defp read_state_query(queryable, _), do: queryable

  # only first page need pin contents
  # TODO: use seperate pined table, which is much more smaller
  defp add_pin_contents_ifneed(contents, CMS.Post, %{community: community} = filter) do
    with {:ok, normal_contents} <- contents,
         true <- Map.has_key?(filter, :community),
         true <- 1 == Map.get(normal_contents, :page_number) do
      {:ok, pined_content} =
        CMS.PinedPost
        |> join(:inner, [p], c in assoc(p, :community))
        |> join(:inner, [p], t in assoc(p, :topic))
        |> join(:inner, [p], content in assoc(p, :post))
        |> where(
          [p, c, t, content],
          c.raw == ^community and t.raw == ^Map.get(filter, :topic, "posts")
        )
        |> select([p, c, t, content], content)
        # 10 pined contents per community/thread, at most
        |> ORM.paginater(%{page: 1, size: 10})
        |> done()

      concat_contents(pined_content, normal_contents)
    else
      _error ->
        contents
    end
  end

  defp add_pin_contents_ifneed(contents, CMS.Job, %{community: _community} = filter) do
    merge_pin_contents(contents, :job, CMS.PinedJob, filter)
  end

  defp add_pin_contents_ifneed(contents, CMS.Video, %{community: _community} = filter) do
    merge_pin_contents(contents, :video, CMS.PinedVideo, filter)
  end

  defp add_pin_contents_ifneed(contents, CMS.Repo, %{community: _community} = filter) do
    merge_pin_contents(contents, :repo, CMS.PinedRepo, filter)
  end

  defp add_pin_contents_ifneed(contents, _querable, _filter), do: contents

  defp merge_pin_contents(contents, thread, pin_schema, %{community: _community} = filter) do
    with {:ok, normal_contents} <- contents,
         true <- Map.has_key?(filter, :community),
         true <- 1 == Map.get(normal_contents, :page_number) do
      {:ok, pined_content} =
        pin_schema
        |> join(:inner, [p], c in assoc(p, :community))
        |> join(:inner, [p], content in assoc(p, ^thread))
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

  defp concat_contents(pined_content, normal_contents) do
    case pined_content |> Map.get(:total_count) do
      0 ->
        {:ok, normal_contents}

      _ ->
        pind_entries =
          pined_content
          |> Map.get(:entries)
          |> Enum.map(&struct(&1, %{pin: true}))

        normal_entries = normal_contents |> Map.get(:entries)

        normal_count = normal_contents |> Map.get(:total_count)
        pind_count = pined_content |> Map.get(:total_count)

        # remote the pined content from normal_entries (if have)
        pind_ids = pick_by(pind_entries, :id)
        normal_entries = Enum.reject(normal_entries, &(&1.id in pind_ids))

        normal_contents
        |> Map.put(:entries, pind_entries ++ normal_entries)
        |> Map.put(:total_count, pind_count + normal_count)
        |> done
    end
  end

  defp create_content_result({:ok, %{add_content_author: result}}), do: {:ok, result}

  # TODO: need more spec error handle
  defp create_content_result({:error, :add_content_author, _result, _steps}) do
    {:error, [message: "create cms content author", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_community, _result, _steps}) do
    {:error, [message: "set community", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_community_flag, _result, _steps}) do
    {:error, [message: "set community flag", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_topic, _result, _steps}) do
    {:error, [message: "set topic", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_tag, result, _steps}) do
    {:error, result}
  end

  defp create_content_result({:error, :log_action, _result, _steps}) do
    {:error, [message: "log action", code: ecode(:create_fails)]}
  end

  defp set_tags(community, thread, content_id, tags) do
    try do
      Enum.each(tags, fn tag ->
        {:ok, _} = ArticleOperation.set_tag(community, thread, %Tag{id: tag.id}, content_id)
      end)

      {:ok, "psss"}
    rescue
      _ -> {:error, [message: "set tag", code: ecode(:create_fails)]}
    end
  end

  defp update_tags(_content, tags_ids) when length(tags_ids) == 0, do: {:ok, :pass}

  # Job is special, the tags in job only represent city, so everytime update
  # tags on job content, should be override the old ones, in this way, every
  # communiies contains this job will have the same city info
  defp update_tags(%CMS.Job{} = content, tags_ids) do
    with {:ok, content} <- ORM.find(CMS.Job, content.id, preload: :tags) do
      city_tags =
        Enum.reduce(tags_ids, [], fn t, acc ->
          {:ok, tag} = ORM.find(Tag, t.id)
          acc ++ [tag]
        end)

      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, city_tags)
      |> Repo.update()
    else
      _ -> {:error, "update city tag"}
    end
  end

  # except Job, other content will just pass, should use set_tag function instead
  defp update_tags(_, _tags_ids), do: {:ok, :pass}

  defp update_content_result({:ok, %{update_content: result}}), do: {:ok, result}
  defp update_content_result({:error, :update_content, result, _steps}), do: {:error, result}
  defp update_content_result({:error, :update_tag, result, _steps}), do: {:error, result}

  defp content_id(:post, id), do: %{post_id: id}
  defp content_id(:job, id), do: %{job_id: id}
  defp content_id(:repo, id), do: %{repo_id: id}
  defp content_id(:video, id), do: %{video_id: id}
end
