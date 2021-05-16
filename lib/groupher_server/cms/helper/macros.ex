defmodule GroupherServer.CMS.Helper.Macros do
  @moduledoc """
  macros for define article related fields in CMS models
  """

  alias GroupherServer.CMS

  @article_threads CMS.Community.article_threads()

  @doc """
  generate belongs to fields for given thread

  e.g:
  belongs_to(:post, Post, foreign_key: :post_id)

  NOTE: should do migration to DB manually
  """
  defmacro article_belongs_to() do
    @article_threads
    |> Enum.map(fn thread ->
      thread_module = unquote(thread) |> to_string |> Recase.to_pascal()

      quote do
        belongs_to(unquote(thread), Module.concat(CMS, thread_module),
          foreign_key: unquote(:"#{thread}_id")
        )
      end
    end)
  end
end
