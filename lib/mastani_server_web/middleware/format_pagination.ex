# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.FormatPagination do
  @behaviour Absinthe.Middleware

  def call(%{errors: [errors], value: nil} = resolution, _) do
    %{resolution | value: [], errors: [errors]}
  end

  def call(%{value: value} = resolution, _) do
    format_pagi(resolution)
  end

  def call(resolution, _), do: resolution

  def format_pagi(resolution) do
    formated = %{
      entries: resolution.value.entries,
      page_number: resolution.value.page_number,
      page_size: resolution.value.page_size,
      total_pages: resolution.value.total_pages,
      total_count: resolution.value.total_entries
    }

    %{resolution | value: formated}
  end
end
