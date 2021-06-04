defmodule GroupherServer.Accounts.Model.UserFollower do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts.Model.User

  @required_fields ~w(user_id follower_id)a

  @type t :: %UserFollower{}
  schema "users_followers" do
    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:follower, User, foreign_key: :follower_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%UserFollower{} = user_follower, attrs) do
    user_follower
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:follower_id)
    |> unique_constraint(:user_id, name: :users_followers_user_id_follower_id_index)
  end
end
