defmodule MastaniServer.Statistics.UserContribute do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts

  @type t :: %UserContribute{}
  schema "user_contributes" do
    field(:count, :integer)
    field(:date, :date)
    belongs_to(:user, Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%UserContribute{} = user_contribute, attrs) do
    user_contribute
    |> cast(attrs, [:date, :count, :user_id])
    |> validate_required([:date, :count, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
