defmodule MastaniServer.CMS.Passport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cms_passports" do
    field(:rules, :map)
    field(:user_id, :id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(passport, attrs) do
    passport
    |> cast(attrs, [:rules, :user_id])
    |> validate_required([:rules, :user_id])
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
