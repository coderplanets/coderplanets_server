defmodule MastaniServer.CMS.PostFavorite do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Post, PostFavorite}
  alias MastaniServer.Accounts

  @required_fields ~w(user_id post_id)a

  schema "posts_favorites" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:post, Post, foreign_key: :post_id)

    timestamps()
  end

  @doc false
  def changeset(%PostFavorite{} = post_favorite, attrs) do
    post_favorite
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :posts_favorites_user_id_post_id_index)
  end
end
