defmodule GroupherServer.CMS.VideoFavorite do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.Video

  @required_fields ~w(user_id video_id)a
  @optional_fields ~w(category_id)a

  @type t :: %VideoFavorite{}
  schema "videos_favorites" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:video, Video, foreign_key: :video_id)

    belongs_to(:category, Accounts.FavoriteCategory)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%VideoFavorite{} = video_favorite, attrs) do
    video_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :videos_favorites_user_id_video_id_index)
  end

  @doc false
  def update_changeset(%VideoFavorite{} = video_favorite, attrs) do
    video_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> unique_constraint(:user_id, name: :videos_favorites_user_id_video_id_index)
  end
end
