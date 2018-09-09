defmodule MastaniServer.CMS.Delegate.ArticleCURD do
  @moduledoc """
  CURD operation on post/job/video ...
  """
  import Ecto.Query, warn: false
  import MastaniServer.CMS.Utils.Matcher
  import Helper.Utils, only: [done: 1]
  import Helper.ErrorCode
  import ShortMaps

  alias MastaniServer.Accounts.User
  alias MastaniServer.{CMS, Repo, Statistics}

  alias CMS.Delegate.ArticleOperation
  alias Helper.{ORM, QueryBuilder}

  alias CMS.{Author, Community, Tag}
  alias Ecto.Multi

  @doc """
  get paged post / job ...
  """
  def paged_contents(queryable, filter) do
    normal_content_fr = filter |> Map.merge(QueryBuilder.default_article_filters())

    queryable
    |> ORM.find_all(normal_content_fr)
    |> add_pin_contents_ifneed(queryable, filter)
  end

  # only first page need pin contents
  defp add_pin_contents_ifneed(contents, queryable, filter) do
    with {:ok, normal_contents} <- contents,
         true <- 1 == Map.get(normal_contents, :page_number) do
      pin_content_fr = filter |> Map.merge(%{pin: true})
      {:ok, pined_content} = queryable |> ORM.find_all(pin_content_fr)

      case pined_content |> Map.get(:total_count) do
        0 ->
          contents

        _ ->
          pind_entries = pined_content |> Map.get(:entries)
          normal_entries = normal_contents |> Map.get(:entries)

          normal_count = normal_contents |> Map.get(:total_count)
          pind_count = pined_content |> Map.get(:total_count)

          normal_contents
          |> Map.put(:entries, pind_entries ++ normal_entries)
          |> Map.put(:total_count, pind_count + normal_count)
          |> done
      end
    else
      _error ->
        contents
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
  def create_content(%Community{id: community_id}, thread, attrs, %User{id: user_id}) do
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

  defp create_content_result({:error, :add_content_author, _result, _steps}) do
    {:error, [message: "assign author", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_community, _result, _steps}) do
    {:error, [message: "set community", code: ecode(:create_fails)]}
  end

  defp create_content_result({:error, :set_tag, result, _steps}) do
    {:error, result}
  end

  defp create_content_result({:error, :log_action, result, _steps}) do
    {:error, [message: "log action", code: ecode(:create_fails)]}
  end

  # if empty just pass
  defp set_tags(community, thread, content_id, []), do: {:ok, "pass"}

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
