defmodule GroupherServer.CMS.PostFavorite do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.Post

  @required_fields ~w(user_id post_id)a
  @optional_fields ~w(category_id)a

  @type t :: %PostFavorite{}
  schema "posts_favorites" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:post, Post, foreign_key: :post_id)

    belongs_to(:category, Accounts.FavoriteCategory)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PostFavorite{} = post_favorite, attrs) do
    post_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :posts_favorites_user_id_post_id_index)
  end

  @doc false
  def update_changeset(%PostFavorite{} = post_favorite, attrs) do
    post_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> unique_constraint(:user_id, name: :posts_favorites_user_id_post_id_index)
  end
end
