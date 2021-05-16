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

  NOTE: should do migration to DB manually:
  数据库层面的 migration 需要手动添加，参考：

  add(:post_id, references(:cms_posts, on_delete: :delete_all))
  add(:job_id, references(:cms_jobs, on_delete: :delete_all))
  add(:repo_id, references(:cms_jobs, on_delete: :delete_all))
  ...
  """
  defmacro article_belongs_to() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        belongs_to(
          unquote(thread),
          Module.concat(CMS, unquote(thread) |> to_string |> Recase.to_pascal()),
          foreign_key: unquote(:"#{thread}_id")
        )
      end
    end)
  end
end
