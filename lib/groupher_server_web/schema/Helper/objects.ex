defmodule GroupherServerWeb.Schema.Helper.Objects do
  @moduledoc """
  general fields used in schema definition
  """
  import Helper.Utils, only: [get_config: 2, plural: 1]

  @article_threads get_config(:article, :threads)

  @doc """
  paged articles helper

  e,g:
  object :paged_blogs do
    field(:entries, list_of(:blog))
    pagination_fields()
  end
  """
  defmacro paged_article_objects() do
    @article_threads
    |> Enum.map(
      &quote do
        object unquote(:"paged_#{plural(&1)}") do
          field(:entries, list_of(unquote(&1)))
          pagination_fields()
        end
      end
    )
  end
end
