defmodule GroupherServer.CMS.Model.CommentUpvote do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.Comment

  @required_fields ~w(comment_id user_id)a

  @type t :: %CommentUpvote{}
  schema "comments_upvotes" do
    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:comment, Comment, foreign_key: :comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommentUpvote{} = comment_upvote, attrs) do
    comment_upvote
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id,
      name: :comments_upvotes_user_id_comment_id_index
    )
  end
end
