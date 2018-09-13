defmodule MastaniServer.CMS.VideoCommunityFlag do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias Helper.Certification
  alias MastaniServer.Accounts
  alias MastaniServer.CMS.{Community, Video}

  @required_fields ~w(video_id community_id)a
  @optional_fields ~w(pin trash)a

  @type t :: %VideoCommunityFlag{}

  schema "videos_communities_flags" do
    belongs_to(:video, Video, foreign_key: :video_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    field(:pin, :boolean)
    field(:trash, :boolean)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoCommunityFlag{} = video_community_flag, attrs) do
    video_community_flag
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:video_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:video_id, name: :videos_communities_flags_video_id_community_id_index)
  end
end
