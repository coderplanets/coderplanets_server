defmodule GroupherServer.CMS.Model.CommentReply do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.Model.Comment

  @required_fields ~w(comment_id reply_to_id)a

  @type t :: %CommentReply{}
  schema "comments_replies" do
    belongs_to(:comment, Comment, foreign_key: :comment_id)
    belongs_to(:reply_to, Comment, foreign_key: :reply_to_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommentReply{} = comment_reply, attrs) do
    comment_reply
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:comment_id)
    |> foreign_key_constraint(:reply_to_id)
  end
end
