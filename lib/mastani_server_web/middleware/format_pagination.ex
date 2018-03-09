# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.FormatPagination do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function

  def call(res, _) do
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
