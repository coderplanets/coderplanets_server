defmodule GroupherServer.CMS.Model.Thread do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields ~w(logo index)a
  @required_fields ~w(title raw)a

  @type t :: %Thread{}
  schema "threads" do
    field(:title, :string)
    field(:raw, :string)
    field(:logo, :string)
    field(:index, :integer)

    timestamps(type: :utc_datetime)
  end

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
