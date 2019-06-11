defmodule GroupherServer.CMS.VideoCommentReply do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.CMS.VideoComment

  @required_fields ~w(video_comment_id reply_id)a

  @type t :: %VideoCommentReply{}
  schema "videos_comments_replies" do
    belongs_to(:video_comment, VideoComment, foreign_key: :video_comment_id)
    belongs_to(:reply, VideoComment, foreign_key: :reply_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoCommentReply{} = video_comment_reply, attrs) do
    video_comment_reply
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:video_comment_id)
    |> foreign_key_constraint(:reply_id)
  end
end
