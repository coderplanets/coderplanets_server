# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.SizeChecker do
  @behaviour Absinthe.Middleware
  @max_page_size 30
  @default_page_size 10
  # 1. if has filter:first and filter:size -> makesure it not too large
  # 2. if not has filter: marge to default first: 5
  # 3. large size should trigger error

  def call(res, _) do
    case valid_size(res.arguments) do
      {:error, msg} ->
        res |> Absinthe.Resolution.put_result({:error, msg})

      arguments ->
        %{res | arguments: arguments}
    end
  end

  defp valid_size(%{filter: %{first: size}} = arg), do: do_size_check(size, arg)

  # Scrivener default size is defined in mastani_server/repo.ex
  # see tuts: https://www.dailydrip.com/topics/elixirsips/drips/phoenix-api-pagination-with-scrivener
  defp valid_size(%{filter: %{size: size}} = arg), do: do_size_check(size, arg)

  defp valid_size(arg), do: Map.merge(arg, %{filter: %{first: @default_page_size}})

  defp do_size_check(size, arg) do
    case size <= @max_page_size and size > 0 do
      true ->
        arg

      _ ->
        {:error,
         "SIZE_RANGE_ERROR: size shuold between 0 and #{@max_page_size}, current: #{size}"}
    end
  end
end
