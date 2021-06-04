defmodule GroupherServer.CMS.Model.RepoContributor do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(avatar nickname html_url)a

  @type t :: %RepoContributor{}
  embedded_schema do
    field(:avatar, :string)
    field(:nickname, :string)
    field(:html_url, :string)
  end

  @doc false
  def changeset(%RepoContributor{} = repo_contributor, attrs) do
    repo_contributor
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
