defmodule GroupherServer.Accounts.Model.UserFollowing do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts.Model.User

  @required_fields ~w(user_id following_id)a

  @type t :: %UserFollowing{}
  schema "users_followings" do
    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:following, User, foreign_key: :following_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%UserFollowing{} = user_following, attrs) do
    user_following
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:following_id)
    |> unique_constraint(:user_id, name: :users_followers_user_id_following_id_index)
  end
end
