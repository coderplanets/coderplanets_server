defmodule GroupherServer.Accounts.Model.WorkBackground do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(company)a
  @optional_fields ~w(title)a

  @type t :: %WorkBackground{}
  embedded_schema do
    field(:company, :string)
    field(:title, :string)
  end

  @doc false
  def changeset(%WorkBackground{} = work_background, attrs) do
    work_background
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end
end
