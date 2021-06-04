defmodule GroupherServer.Accounts.Model.EducationBackground do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(school)a
  @optional_fields ~w(major)a

  @type t :: %EducationBackground{}
  embedded_schema do
    field(:school, :string)
    field(:major, :string)
  end

  @doc false
  def changeset(%EducationBackground{} = education_background, attrs) do
    education_background
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end
end
