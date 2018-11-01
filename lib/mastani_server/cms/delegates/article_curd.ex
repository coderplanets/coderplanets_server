defmodule MastaniServer.CMS.Delegate.ArticleCURD do
  @moduledoc """
  CURD operation on post/job/video ...
  """
  import Ecto.Query, warn: false
  import MastaniServer.CMS.Utils.Matcher
  import Helper.Utils, only: [done: 1]
  import Helper.ErrorCode
  import ShortMaps

  alias MastaniServer.Repo

  alias MastaniServer.Accounts.User
  alias MastaniServer.{CMS, Statistics}

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

  defp content_id(:post, id), do: %{post_id: id}
  defp content_id(:job, id), do: %{job_id: id}
  defp content_id(:repo, id), do: %{repo_id: id}
  defp content_id(:video, id), do: %{video_id: id}

  @doc """
  get paged post / job ...
  """
  def paged_contents(queryable, filter) do
    queryable
    |> flag_query(filter)
    |> ORM.find_all(filter)
    |> add_pin_contents_ifneed(queryable, filter)
  end

  defp flag_query(queryable, filter, flag \\ %{}) do
    flag = %{pin: false, trash: false} |> Map.merge(flag)

    # NOTE: this case judge is used for test case
    case filter |> Map.has_key?(:community) do
      true ->
        queryable
        |> join(:inner, [q], f in assoc(q, :community_flags))
        |> where([q, f], f.pin == ^flag.pin and f.trash == ^flag.trash)
        |> join(:inner, [q, f], c in assoc(f, :community))
        |> where([q, f, c], c.raw == ^filter.community)

      false ->
        queryable
    end
  end

  # only first page need pin contents
  defp add_pin_contents_ifneed(contents, queryable, filter) do
    with {:ok, normal_contents} <- contents,
         true <- Map.has_key?(filter, :community),
         true <- 1 == Map.get(normal_contents, :page_number) do
      {:ok, pined_content} =
        queryable
        |> flag_query(filter, %{pin: true})
        |> ORM.find_all(filter)

      # TODO: add hot post pin/trash state ?
      # don't by flag_changeset, dataloader make things complex
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
        # NOTE: this is tricy, should use dataloader refactor
        pind_entries =
          pined_content
          |> Map.get(:entries)
          |> Enum.map(&struct(&1, %{pin: true}))

        normal_entries = normal_contents |> Map.get(:entries)

        normal_count = normal_contents |> Map.get(:total_count)
        pind_count = pined_content |> Map.get(:total_count)

        normal_contents
        |> Map.put(:entries, pind_entries ++ normal_entries)
        |> Map.put(:total_count, pind_count + normal_count)
        |> done
    end
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
      |> Multi.run(:add_content_author, fn _ ->
        action.target
        |> struct()
        |> action.target.changeset(attrs)
        |> Ecto.Changeset.put_change(:author_id, author.id)
        |> Repo.insert()
      end)
      |> Multi.run(:set_community, fn %{add_content_author: content} ->
        ArticleOperation.set_community(community, thread, content.id)
      end)
      |> Multi.run(:set_topic, fn %{add_content_author: content} ->
        topic_title =
          case attrs |> Map.has_key?(:topic) do
            true -> attrs.topic
            false -> "posts"
          end

        ArticleOperation.set_topic(%Topic{title: topic_title}, thread, content.id)
      end)
      |> Multi.run(:set_community_flag, fn %{add_content_author: content} ->
        # TODO: remove this judge, as content should have a flag
        case action |> Map.has_key?(:flag) do
          true ->
            ArticleOperation.set_community_flags(content, community.id, %{
              pin: false,
              trash: false
            })

          false ->
            {:ok, "pass"}
        end
      end)
      |> Multi.run(:set_tag, fn %{add_content_author: content} ->
        case attrs |> Map.has_key?(:tags) do
          true -> set_tags(community, thread, content.id, attrs.tags)
          false -> {:ok, "pass"}
        end
      end)
      |> Multi.run(:log_action, fn _ ->
        Statistics.log_publish_action(%User{id: user_id})
      end)
      |> Repo.transaction()
      |> create_content_result()
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

  defp create_content_result({:error, :set_topic, result, _steps}) do
    IO.inspect(result, label: "set topic")
    {:error, [message: "set topic", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_tag, result, _steps}) do
    {:error, result}
  end

  defp create_content_result({:error, :log_action, _result, _steps}) do
    {:error, [message: "log action", code: ecode(:create_fails)]}
  end

  # if empty just pass
  defp set_tags(_community, _thread, _content_id, []), do: {:ok, "pass"}

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

  @doc """
  get CMS contents
  post's favorites/stars/comments ...
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """
  def reaction_users(thread, react, id, %{page: page, size: size} = filters) do
    # when valid_reaction(thread, react) do
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
end
