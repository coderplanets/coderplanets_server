defmodule GroupherServer.CMS.VideoCommentLike do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.VideoComment

  @required_fields ~w(video_comment_id user_id)a

  @type t :: %VideoCommentLike{}
  schema "videos_comments_likes" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:video_comment, VideoComment, foreign_key: :video_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoCommentLike{} = video_comment_like, attrs) do
    video_comment_like
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:video_comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :videos_comments_likes_user_id_video_comment_id_index)
  end
end
