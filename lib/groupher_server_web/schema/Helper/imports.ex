defmodule GroupherServerWeb.Schema.Helper.Imports do
  @moduledoc """
  helper for import cms article related fields
  """

  import Helper.Utils, only: [get_config: 2]
  @article_threads get_config(:article, :threads)

  alias GroupherServerWeb.Schema.{CMS}

  @doc """
  import article fields based on @article_threads
  e.g:
  ----
  import_types(:cms_post_mutations)
  import_types(:cms_job_mutations)
  # ...
  """
  defmacro import_article_fields(:mutations) do
    @article_threads
    |> Enum.map(
      &quote do
        import_fields(unquote(:"cms_#{&1}_mutations"))
      end
    )
  end

  @doc """
  import article fields based on @article_threads
  e.g:
  ----
  import_types(CMS.Mutations.Post)
  import_types(CMS.Mutations.Job)
  # ...
  """
  defmacro import_article_fields(:mutations, :module) do
    @article_threads
    |> Enum.map(
      &quote do
        import_types(unquote(Module.concat(CMS.Mutations, Recase.to_pascal(to_string(&1)))))
      end
    )
  end
end
