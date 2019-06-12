defmodule GroupherServer.CMS.PostViewer do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.Post

  @required_fields ~w(post_id user_id)a

  @type t :: %PostViewer{}
  schema "posts_viewers" do
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PostViewer{} = post_viewer, attrs) do
    post_viewer
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :posts_viewers_post_id_user_id_index)
  end
end
