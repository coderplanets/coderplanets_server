defmodule MastaniServer.CMS.PinedVideo do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Community, Video}

  @required_fields ~w(video_id community_id)a

  @type t :: %PinedVideo{}
  schema "pined_videos" do
    belongs_to(:video, Video, foreign_key: :video_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PinedVideo{} = pined_video, attrs) do
    pined_video
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:video_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:pined_videos, name: :pined_videos_video_id_community_id_index)
  end
end
