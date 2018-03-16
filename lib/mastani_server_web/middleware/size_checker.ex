# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.SizeChecker do
  @behaviour Absinthe.Middleware
  @max_page_size 30
  @default_page_size 20

  import MastaniServer.Utils.Helper, only: [handle_absinthe_error: 2]
  # 1. if has filter:first and filter:size -> makesure it not too large
  # 2. if not has filter: marge to default first: 5
  # 3. large size should trigger error

  def call(resolution, _) do
    case valid_size(resolution.arguments) do
      {:error, msg} ->
        resolution |> handle_absinthe_error(msg)

      arguments ->
        %{resolution | arguments: sort_desc_by_default(arguments)}
    end
  end

  defp sort_desc_by_default(%{filter: filter} = arguments) do
    filter =
      if Map.has_key?(filter, :sort),
        do: filter,
        else: filter |> Map.merge(%{sort: :desc_inserted})

    arguments |> Map.merge(%{filter: filter})
  end

  defp valid_size(%{filter: %{first: size}} = arg), do: do_size_check(size, arg)
  # Scrivener default size is defined in mastani_server/repo.ex
  # see tuts: https://www.dailydrip.com/topics/elixirsips/drips/phoenix-api-pagination-with-scrivener
  defp valid_size(%{filter: %{size: size}} = arg), do: do_size_check(size, arg)

  defp valid_size(arg), do: arg |> Map.merge(%{filter: %{first: @default_page_size}})

  defp do_size_check(size, arg) do
    case size in 1..@max_page_size do
      true ->
        arg

      _ ->
        {:error,
         "SIZE_RANGE_ERROR: size shuold between 0 and #{@max_page_size}, current: #{size}"}
    end
  end
end
