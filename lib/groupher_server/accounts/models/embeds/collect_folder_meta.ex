defmodule GroupherServer.Accounts.Model.Embeds.CollectFolderMeta.Macros do
  @moduledoc """
  general fields for each folder meta

  e.g:
    field(:has_post, :boolean, default: false)
    field(:post_count, :integer, default: 0)
    field(:has_job, :boolean, default: false)
    field(:job_count, :integer, default: 0)
    field(:has_repo, :boolean, default: false)
    field(:repo_count, :integer, default: 0)
  """
  import Helper.Utils, only: [get_config: 2]

  @article_threads get_config(:article, :threads)

  defmacro threads_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        field(unquote(:"has_#{thread}"), :boolean, default: false)
        field(unquote(:"#{thread}_count"), :integer, default: 0)
      end
    end)
  end
end

defmodule GroupherServer.Accounts.Model.Embeds.CollectFolderMeta do
  @moduledoc """
  general article meta info for articles
  """
  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.Accounts.Model.Embeds.CollectFolderMeta.Macros
  import Helper.Utils, only: [get_config: 2]

  @article_threads get_config(:article, :threads)

  @optional_fields Enum.map(@article_threads, &:"#{&1}_count") ++
                     Enum.map(@article_threads, &:"has_#{&1}")

  def default_meta() do
    @article_threads
    |> Enum.reduce([], fn thread, acc -> acc ++ ["#{thread}_count": 0, "has_#{thread}": false] end)
    |> Enum.into(%{})
  end

  embedded_schema do
    threads_fields()
  end

  def changeset(struct, params) do
    struct |> cast(params, @optional_fields)
  end
end
