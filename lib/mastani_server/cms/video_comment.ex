defmodule MastaniServer.CMS.VideoComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts

  alias MastaniServer.CMS.{
    Video,
    # PostCommentDislike,
    # PostCommentLike,
    VideoCommentReply
  }

  @required_fields ~w(body author_id video_id floor)a
  @optional_fields ~w(reply_id)a

  @type t :: %VideoComment{}
  schema "videos_comments" do
    field(:body, :string)
    field(:floor, :integer)
    belongs_to(:author, Accounts.User, foreign_key: :author_id)
    belongs_to(:video, Video, foreign_key: :video_id)
    belongs_to(:reply_to, VideoComment, foreign_key: :reply_id)

    has_many(:replies, {"videos_comments_replies", VideoCommentReply})
    # has_many(:likes, {"posts_comments_likes", PostCommentLike})
    # has_many(:dislikes, {"posts_comments_dislikes", PostCommentDislike})

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoComment{} = video_comment, attrs) do
    video_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:body, min: 1)
    |> foreign_key_constraint(:video_id)
    |> foreign_key_constraint(:author_id)
  end
end
