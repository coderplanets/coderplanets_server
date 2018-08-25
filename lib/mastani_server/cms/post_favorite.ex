defmodule MastaniServer.CMS.PostFavorite do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts
  alias MastaniServer.CMS.Post

  @required_fields ~w(user_id post_id)a
  @optional_fields ~w(category_title category_id)a

  @type t :: %PostFavorite{}
  schema "posts_favorites" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:post, Post, foreign_key: :post_id)
    # has_many(:category, UserFavoriteCategory)
    belongs_to(:category, Accounts.FavoriteCategory)
    field(:category_title, :string, default: "all")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PostFavorite{} = post_favorite, attrs) do
    post_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :posts_favorites_user_id_post_id_index)
  end
end
