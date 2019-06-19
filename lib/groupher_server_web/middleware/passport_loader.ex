defmodule GroupherServerWeb.Middleware.PassportLoader do
  @behaviour Absinthe.Middleware
  import GroupherServer.CMS.Utils.Matcher
  import Helper.Utils
  import Helper.ErrorCode

  import ShortMaps

  alias GroupherServer.CMS
  alias Helper.ORM

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(
        %{context: %{cur_user: _}, arguments: ~m(community_id)a} = resolution,
        source: :community
      ) do
    case ORM.find(CMS.Community, community_id) do
      {:ok, community} ->
        arguments = resolution.arguments |> Map.merge(%{passport_communities: [community]})
        %{resolution | arguments: arguments}

      {:error, err_msg} ->
        resolution
        |> handle_absinthe_error(err_msg, ecode(:passport))
    end
  end

  # def call(%{context: %{cur_user: cur_user}, arguments: %{id: id}} = resolution, [source: .., base: ..]) do
  # Loader 应该使用 Map 作为参数，以方便模式匹配
  def call(%{context: %{cur_user: _}, arguments: %{id: id}} = resolution, args) do
    with {:ok, thread, react} <- parse_source(args, resolution),
         {:ok, action} <- match_action(thread, react),
         {:ok, preload} <- parse_preload(action, args),
         {:ok, content} <- ORM.find(action.reactor, id, preload: preload) do
      resolution
      |> load_owner_info(react, content)
      |> load_source(content)
      |> load_community_info(content, args)
    else
      {:error, err_msg} ->
        resolution
        |> handle_absinthe_error(err_msg, ecode(:passport))
    end
  end

  def call(resolution, _) do
    # TODO communiy in args
    resolution
  end

  def load_source(resolution, content) do
    arguments = resolution.arguments |> Map.merge(%{passport_source: content})
    %{resolution | arguments: arguments}
  end

  # 取得 content 里面的 conmunities 字段
  def load_community_info(resolution, content, args) do
    communities = content |> Map.get(parse_base(args))

    # check if communities is a List
    communities = if is_list(communities), do: communities, else: [communities]

    arguments = resolution.arguments |> Map.merge(%{passport_communities: communities})
    %{resolution | arguments: arguments}
  end

  defp parse_preload(action, args) do
    {:ok, _, react} = parse_source(args)

    case react == :comment do
      true ->
        {:ok, action.preload}

      false ->
        {:ok, [action.preload, parse_base(args)]}
    end
  end

  def load_owner_info(%{context: %{cur_user: cur_user}} = resolution, react, content) do
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

  # typical usage is delete_comment, should load conent by thread
  defp parse_source([source: [:arg_thread, react]], %{arguments: %{thread: thread}}) do
    parse_source(source: [thread, react])
  end

  defp parse_source(args, _resolution) do
    parse_source(args)
  end

  defp parse_source(args) do
    case Keyword.has_key?(args, :source) do
      false -> {:error, "Invalid.option: #{args}"}
      true -> args |> Keyword.get(:source) |> match_source
    end
  end

  defp match_source([thread, react]), do: {:ok, thread, react}
  defp match_source(thread), do: {:ok, thread, :self}

  defp parse_base(args) do
    Keyword.get(args, :base) || :communities
  end
end
