defmodule GroupherServer.Accounts.Embeds.CollectFolderMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields ~w(id has_post has_job has_repo)a

  @default_threads_flags %{
    has_post: false,
    has_job: false,
    has_repo: false
  }

  @default_meta Map.merge(%{}, @default_threads_flags)

  @doc "for test usage"
  def default_meta(), do: @default_meta
  def default_threads_flags(), do: @default_threads_flags

  embedded_schema do
    field(:has_post, :boolean, default: false)
    field(:has_job, :boolean, default: false)
    field(:has_repo, :boolean, default: false)
    ###
    # field(:has_works, :boolean, default: false)
    # field(:has_cool_guide, :boolean, default: false)
    # field(:has_meetup, :boolean, default: false)
  end

  def changeset(struct, params) do
    struct |> cast(params, @optional_fields)
  end
end
