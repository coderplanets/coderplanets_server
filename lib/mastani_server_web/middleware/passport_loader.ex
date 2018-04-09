defmodule MastaniServerWeb.Middleware.PassportLoader do
  @behaviour Absinthe.Middleware
  import MastaniServer.CMSMisc
  import Helper.Utils

  alias Helper.ORM

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  # def call(%{context: %{cur_user: cur_user}, arguments: %{id: id}} = resolution, [source: .., base: ..]) do
  # Loader 应该使用 Map 作为参数，以方便模式匹配
  def call(%{context: %{cur_user: _}, arguments: %{id: id}} = resolution, args) do
    with {:ok, part, react} <- parse_source(args),
         {:ok, action} <- match_action(part, react),
         {:ok, content} <-
           ORM.find(action.reactor, id, preload: [action.preload, parse_base(args)]) do
      resolution
      |> add_owner_info(react, content)
      |> add_source(content)
      |> add_community_info(content, args)
    else
      {:error, err_msg} ->
        resolution
        |> handle_absinthe_error(err_msg)
    end
  end

  def call(resolution, _) do
    # TODO communiy in args
    resolution
  end

  def add_owner_info(%{context: %{cur_user: cur_user}} = resolution, react, content) do
    content_author_id =
      cond do
        react == :comment ->
          content.author.id

        true ->
          content.author.user_id
      end

    case content_author_id == cur_user.id do
      true ->
        arguments = resolution.arguments |> Map.merge(%{passport_is_owner: true})
        %{resolution | arguments: arguments}

      _ ->
        resolution
    end
  end

  def add_source(resolution, content) do
    arguments = resolution.arguments |> Map.merge(%{passport_source: content})
    %{resolution | arguments: arguments}
  end

  def add_community_info(resolution, content, args) do
    communities = content |> Map.get(parse_base(args))

    # check if communities is a List
    communities = if is_list(communities), do: communities, else: [communities]

    arguments = resolution.arguments |> Map.merge(%{passport_communities: communities})
    %{resolution | arguments: arguments}
  end

  # defp parse_args(args, :owner) do
  defp parse_source(args) do
    case Keyword.has_key?(args, :source) do
      nil -> {:error, "Invalid.option: #{args}"}
      true -> Keyword.get(args, :source) |> match_source
    end
  end

  defp match_source([part, react]), do: {:ok, part, react}
  defp match_source(part), do: {:ok, part, :self}

  defp parse_base(args) do
    Keyword.get(args, :base) || :communities
  end
end
