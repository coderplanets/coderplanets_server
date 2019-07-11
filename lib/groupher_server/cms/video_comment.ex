defmodule GroupherServer.CMS.VideoComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias CMS.{
    Video,
    VideoCommentDislike,
    VideoCommentLike,
    VideoCommentReply
  }

  alias Helper.HTML

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
    has_many(:likes, {"videos_comments_likes", VideoCommentLike})
    has_many(:dislikes, {"videos_comments_dislikes", VideoCommentDislike})

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoComment{} = video_comment, attrs) do
    video_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%VideoComment{} = video_comment, attrs) do
    video_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> foreign_key_constraint(:video_id)
    |> foreign_key_constraint(:author_id)
    |> validate_length(:body, min: 3, max: 2000)
    |> HTML.safe_string(:body)
  end
end
