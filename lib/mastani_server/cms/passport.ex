defmodule MastaniServer.CMS.Passport do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts

  @type t :: %Passport{}
  schema "cms_passports" do
    field(:rules, :map)
    belongs_to(:user, Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Passport{} = passport, attrs) do
    passport
    |> cast(attrs, [:rules, :user_id])
    |> validate_required([:rules, :user_id])
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
