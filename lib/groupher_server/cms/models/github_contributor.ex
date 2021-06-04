defmodule GroupherServer.CMS.Model.GithubContributor do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(github_id avatar nickname html_url)a
  @optional_fields ~w(bio company location)a

  @type t :: %GithubContributor{}
  embedded_schema do
    field(:github_id, :string)
    field(:avatar, :string)
    field(:nickname, :string)
    field(:bio, :string)
    field(:company, :string)
    field(:location, :string)
    field(:html_url, :string)
  end

  @doc false
  def changeset(%GithubContributor{} = github_contributor, attrs) do
    github_contributor
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
