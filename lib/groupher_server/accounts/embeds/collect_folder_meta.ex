defmodule GroupherServer.Accounts.Embeds.CollectFolderMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields ~w(id has_post has_job has_repo post_count job_count repo_count)a

  @doc "for test usage"

  embedded_schema do
    field(:has_post, :boolean, default: false)
    field(:post_count, :integer, default: 0)
    field(:has_job, :boolean, default: false)
    field(:job_count, :integer, default: 0)
    field(:has_repo, :boolean, default: false)
    field(:repo_count, :integer, default: 0)
    ###
    # field(:has_works, :boolean, default: false)
    # field(:has_cool_guide, :boolean, default: false)
    # field(:has_meetup, :boolean, default: false)
  end

  def changeset(struct, params) do
    struct |> cast(params, @optional_fields)
  end
end
