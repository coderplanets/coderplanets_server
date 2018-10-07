defmodule MastaniServer.CMS.VideoStar do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts
  alias MastaniServer.CMS.Video

  @required_fields ~w(user_id video_id)a

  @type t :: %VideoStar{}
  schema "videos_stars" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:video, Video, foreign_key: :video_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoStar{} = video_star, attrs) do
    video_star
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :videos_stars_user_id_video_id_index)
  end
end
