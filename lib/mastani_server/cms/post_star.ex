defmodule MastaniServer.CMS.PostStar do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Post, PostStar}
  alias MastaniServer.Accounts

  @required_fields ~w(user_id post_id)a

  schema "posts_stars" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:post, Post, foreign_key: :post_id)

    timestamps()
  end

  @doc false
  def changeset(%PostStar{} = post_star, attrs) do
    # |> unique_constraint(:user_id, name: :favorites_user_id_article_id_index)
    post_star
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :posts_stars_user_id_post_id_index)
  end
end
