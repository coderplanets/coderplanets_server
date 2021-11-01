defmodule GroupherServer.CMS.Model.City do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  # alias GroupherServer.CMS

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(title)a
  @optional_fields ~w(logo desc raw)a

  @type t :: %City{}
  schema "cms_cities" do
    ## mailstone
    field(:title, :string)
    field(:logo, :string)
    field(:desc, :string)
    field(:raw, :string)

    timestamps()
  end

  @doc false
  def changeset(%City{} = city, attrs) do
    city
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%City{} = city, attrs) do
    city
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> generl_changeset
  end

  defp generl_changeset(changeset) do
    changeset
    |> validate_length(:title, min: 1, max: 100)
  end
end
