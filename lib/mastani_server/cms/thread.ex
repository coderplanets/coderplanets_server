defmodule MastaniServer.CMS.Thread do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Thread}

  schema "threads" do
    field(:title, :string)
    field(:raw, :string)
    field(:logo, :string)

    timestamps(type: :utc_datetime)
  end

  # TODO: @required_fields ~w(title raw)a
  @required_fields ~w(title raw)a
  @optional_fields ~w(logo)a

  @doc false
  def changeset(%Thread{} = thread, attrs) do
    thread
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 2, max: 20)
    |> validate_length(:raw, min: 2, max: 20)
    |> unique_constraint(:title)

    # |> unique_constraint(:raw)
  end
end
