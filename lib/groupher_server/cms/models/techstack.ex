defmodule GroupherServer.CMS.Model.Techstack do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  # alias GroupherServer.CMS

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(title raw)a
  @optional_fields ~w(logo desc home_link community_link category)a

  @type t :: %Techstack{}
  schema "cms_techstacks" do
    ## mailstone
    field(:title, :string)
    field(:raw, :string)
    field(:logo, :string)
    field(:desc, :string)

    field(:home_link, :string)
    field(:community_link, :string)
    field(:category, :string)

    timestamps()
  end

  @doc false
  def changeset(%Techstack{} = techstack, attrs) do
    techstack
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Techstack{} = techstack, attrs) do
    techstack
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> generl_changeset
  end

  defp generl_changeset(changeset) do
    changeset
    |> validate_length(:title, min: 1, max: 100)
  end
end
