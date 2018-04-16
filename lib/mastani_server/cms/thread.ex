defmodule MastaniServer.CMS.Thread do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Thread}

  schema "community_threads" do
    field(:title, :string)

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(title)a
  @optional_fields ~w(title)a

  @doc false
  def changeset(%Thread{} = thread, attrs) do
    thread
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    # TODO
    # |> validate_inclusion(:title, Certification.editor_titles(:cms))
    |> unique_constraint(:title)
  end
end
