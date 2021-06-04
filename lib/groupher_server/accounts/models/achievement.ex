defmodule GroupherServer.Accounts.Model.Achievement do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.Accounts.Model.{User, SourceContribute}

  @required_fields ~w(user_id)a
  @optional_fields ~w(articles_upvotes_count articles_collects_count contents_watched_count followers_count reputation donate_member senior_member sponsor_member)a

  @type t :: %Achievement{}
  schema "user_achievements" do
    belongs_to(:user, User)

    field(:articles_upvotes_count, :integer, default: 0)
    field(:articles_collects_count, :integer, default: 0)
    field(:contents_watched_count, :integer, default: 0)
    field(:followers_count, :integer, default: 0)
    field(:reputation, :integer, default: 0)
    # source_contribute
    embeds_one(:source_contribute, SourceContribute, on_replace: :delete)

    field(:donate_member, :boolean, default: false)
    field(:senior_member, :boolean, default: false)
    field(:sponsor_member, :boolean, default: false)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Achievement{} = achievement, attrs) do
    achievement
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
  end

  @doc false
  def update_changeset(%Achievement{} = achievement, attrs) do
    achievement
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> foreign_key_constraint(:user_id)
  end
end
