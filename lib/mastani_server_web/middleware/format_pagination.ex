# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.FormatPagination do
  @behaviour Absinthe.Middleware

  def call(res, _) do
    case List.first(res.errors) do
      nil -> format_pagi(res)
      _ -> %{res | value: [], errors: res.errors}
    end
  end

  def format_pagi(res) do
    formated = %{
      entries: res.value.entries,
      page_number: res.value.page_number,
      page_size: res.value.page_size,
      total_pages: res.value.total_pages,
      total_count: res.value.total_entries
    }

    %{res | value: formated}
  end
end
