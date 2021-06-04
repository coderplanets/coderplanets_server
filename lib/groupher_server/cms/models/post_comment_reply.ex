defmodule GroupherServer.CMS.Model.PostCommentReply do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.PostComment

  @required_fields ~w(post_comment_id reply_id)a

  @type t :: %PostCommentReply{}
  schema "posts_comments_replies" do
    belongs_to(:post_comment, PostComment, foreign_key: :post_comment_id)
    belongs_to(:reply, PostComment, foreign_key: :reply_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PostCommentReply{} = post_comment_reply, attrs) do
    post_comment_reply
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_comment_id)
    |> foreign_key_constraint(:reply_id)
  end
end
