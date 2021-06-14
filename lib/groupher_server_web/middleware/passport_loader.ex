defmodule GroupherServerWeb.Middleware.PassportLoader do
  @moduledoc """
  load related passport from source
  """
  @behaviour Absinthe.Middleware

  import GroupherServer.CMS.Helper.Matcher
  import Helper.Utils
  import Helper.ErrorCode

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Comment, Community}

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  @doc "load community"
  def call(%{context: %{cur_user: _}, arguments: arguments} = resolution, source: :community) do
    case ORM.find(Community, arguments.community_id) do
      {:ok, community} ->
        %{resolution | arguments: Map.put(arguments, :passport_communities, [community])}

      {:error, err_msg} ->
        resolution |> handle_absinthe_error(err_msg, ecode(:passport))
    end
  end

  @doc "load article comment"
  def call(%{context: %{cur_user: _}, arguments: %{id: id}} = resolution, source: :comment) do
    case ORM.find(Comment, id, preload: :author) do
      {:ok, comment} ->
        resolution
        |> assign_owner_info(:comment, comment)
        |> assign_source(comment)

      {:error, err_msg} ->
        resolution |> handle_absinthe_error(err_msg, ecode(:passport))
    end
  end

  # def call(%{context: %{cur_user: cur_user}, arguments: %{id: id}} = resolution, [source: .., base: ..]) do
  # Loader 应该使用 Map 作为参数，以方便模式匹配
  def call(%{context: %{cur_user: _}, arguments: %{id: id}} = resolution, source: thread) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id, preload: [:author, :communities]) do
      resolution
      |> assign_owner_info(:article, article)
      |> assign_source(article)
      |> assign_article_communities_info(article)
    else
      {:error, err_msg} -> handle_absinthe_error(resolution, err_msg, ecode(:passport))
    end
  end

  def call(resolution, _), do: resolution

  def assign_source(%{arguments: arguments} = resolution, article) do
    %{resolution | arguments: Map.put(arguments, :passport_source, article)}
  end

  defp assign_owner_info(%{context: %{cur_user: cur_user}} = resolution, react, article) do
    article_author_id = if react == :comment, do: article.author.id, else: article.author.user_id

    case article_author_id == cur_user.id do
      true -> %{resolution | arguments: Map.put(resolution.arguments, :passport_is_owner, true)}
      _ -> resolution
    end
  end

  # 取得 article 里面的 conmunities 字段
  defp assign_article_communities_info(resolution, article) do
    arguments = resolution.arguments |> Map.merge(%{passport_communities: article.communities})
    %{resolution | arguments: arguments}
  end
end
