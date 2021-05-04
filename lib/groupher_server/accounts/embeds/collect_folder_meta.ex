defmodule GroupherServer.CMS.Embeds.CollectFolderMeta.Macros do
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
  alias GroupherServer.Accounts.CollectFolder

  @supported_threads CollectFolder.supported_threads()

  defmacro threads_fields() do
    @supported_threads
    |> Enum.map(fn thread ->
      quote do
        field(unquote(:"has_#{thread}"), :boolean, default: false)
        field(unquote(:"#{thread}_count"), :integer, default: 0)
      end
    end)
  end
end

defmodule GroupherServer.Accounts.Embeds.CollectFolderMeta do
  @moduledoc """
  general article meta info for article-like content, like @supported_threads
  """
  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.CMS.Embeds.CollectFolderMeta.Macros

  alias GroupherServer.Accounts.CollectFolder

  @supported_threads CollectFolder.supported_threads()

  @optional_fields Enum.map(@supported_threads, &:"#{&1}_count") ++
                     Enum.map(@supported_threads, &:"has_#{&1}")

  def default_meta() do
    @supported_threads
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
