defmodule GroupherServer.CMS.Model.RepoDocument do
  @moduledoc """
  mainly for full-text search
  """
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.Model.Repo

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(body body_html repo_id)a
  @optional_fields []

  @type t :: %RepoDocument{}
  schema "repo_documents" do
    belongs_to(:repo, Repo, foreign_key: :repo_id)

    field(:body, :string)
    field(:body_html, :string)
    field(:toc, :map)
  end

  @doc false
  def changeset(%RepoDocument{} = repo, attrs) do
    repo
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  def update_changeset(%RepoDocument{} = repo, attrs) do
    repo
    |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
