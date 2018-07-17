defmodule MastaniServer.CMS.PostCommentLike do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts
  alias MastaniServer.CMS.PostComment

  @required_fields ~w(post_comment_id user_id)a

  @type t :: %PostCommentLike{}
  schema "posts_comments_likes" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:post_comment, PostComment, foreign_key: :post_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PostCommentLike{} = post_comment_like, attrs) do
    post_comment_like
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :posts_comments_likes_user_id_post_comment_id_index)
  end
end
