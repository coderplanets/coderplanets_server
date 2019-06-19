defmodule GroupherServer.CMS.PostStar do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.Post

  @required_fields ~w(user_id post_id)a

  @type t :: %PostStar{}
  schema "posts_stars" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:post, Post, foreign_key: :post_id)

    timestamps(type: :utc_datetime)
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
