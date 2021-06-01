# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule GroupherServerWeb.Middleware.PageSizeProof do
  @moduledoc """
  make sure size less than max limit
  """

  @behaviour Absinthe.Middleware

  import Helper.Utils, only: [handle_absinthe_error: 3, get_config: 2]
  import Helper.ErrorCode

  @max_page_size get_config(:general, :page_size)
  @inner_page_size get_config(:general, :inner_page_size)

  # 1. if has filter:first and filter:size -> makesure it not too large
  # 2. if not has filter: marge to default first: 5
  # 3. large size should trigger error
  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(
        %{context: %{cur_user: %{customization: customization}}, arguments: arguments} =
          resolution,
        args
      )
      when not is_nil(customization) do
    # NOTE:  c11n display_density should also linted by page limit,
    # otherwise dataloader will crash for empty extra items
    size = customization.display_density |> String.to_integer() |> min(@max_page_size)

    case Map.has_key?(arguments, :filter) do
      true ->
        filter = arguments.filter |> Map.merge(%{size: size})
        arguments = arguments |> Map.merge(%{filter: filter})
        %{resolution | arguments: set_sort_ifneed(arguments, args)}

      false ->
        arguments = arguments |> Map.merge(%{filter: %{page: 1, size: size, first: size}})
        %{resolution | arguments: arguments}
    end
  end

  def call(resolution, args) do
    case valid_size(resolution.arguments) do
      {:error, msg} -> resolution |> handle_absinthe_error(msg, ecode(:pagination))
      arguments -> %{resolution | arguments: set_sort_ifneed(arguments, args)}
    end
  end

  defp set_sort_ifneed(%{filter: filter} = arguments, args) do
    case args do
      [] ->
        sort_desc_by_default(arguments)

      [default_sort: :desc_active] ->
        Map.merge(arguments, %{filter: Map.merge(%{sort: :desc_active}, filter)})
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
  defp valid_size(%{filter: %{size: size}} = arg), do: do_size_check(size, arg)

  # defp valid_size(arg), do: arg |> Map.merge(%{filter: %{first: @inner_page_size}})
  defp valid_size(arg),
    do: arg |> Map.merge(%{filter: %{page: 1, size: @max_page_size, first: @inner_page_size}})

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
