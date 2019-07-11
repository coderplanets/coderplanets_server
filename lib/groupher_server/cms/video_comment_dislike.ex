defmodule GroupherServer.CMS.VideoCommentDislike do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}
  alias CMS.VideoComment

  @required_fields ~w(video_comment_id user_id)a

  @type t :: %VideoCommentDislike{}
  schema "videos_comments_dislikes" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:video_comment, VideoComment, foreign_key: :video_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoCommentDislike{} = video_comment_dislike, attrs) do
    video_comment_dislike
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:video_comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :videos_comments_dislikes_user_id_video_comment_id_index)
  end
end
