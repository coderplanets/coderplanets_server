defmodule MastaniServer.Accounts.Achievement do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.{User, SourceContribute}

  @required_fields ~w(user_id)a
  @optional_fields ~w(contents_stared_count contents_favorited_count contents_watched_count followers_count reputation)a

  @type t :: %Achievement{}
  schema "user_achievements" do
    belongs_to(:user, User)

    field(:contents_stared_count, :integer, default: 0)
    field(:contents_favorited_count, :integer, default: 0)
    field(:contents_watched_count, :integer, default: 0)
    field(:followers_count, :integer, default: 0)
    field(:reputation, :integer, default: 0)
    # source_contribute
    embeds_one(:source_contribute, SourceContribute, on_replace: :delete)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Achievement{} = achievement, attrs) do
    achievement
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
  end
end
