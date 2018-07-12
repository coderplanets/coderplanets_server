defmodule MastaniServer.CMS.RepoBuilder do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{RepoBuilder}

  @required_fields ~w(nickname avatar link)a
  @optional_fields ~w(bio)

  schema "cms_repo_users" do
    field(:nickname, :string)
    field(:avatar, :string)
    field(:link, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%RepoBuilder{} = repo_builder, attrs) do
    repo_builder
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end
end
