defmodule GroupherServer.CMS.VideoViewer do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}
  alias CMS.Video

  @required_fields ~w(video_id user_id)a

  @type t :: %VideoViewer{}
  schema "videos_viewers" do
    belongs_to(:video, Video, foreign_key: :video_id)
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoViewer{} = video_viewer, attrs) do
    video_viewer
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :videos_viewers_video_id_user_id_index)
  end
end
