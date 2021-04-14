defmodule GroupherServer.CMS.Embeds.ArticleCommentEmotion do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS.Embeds

  @optional_fields ~w(downvote_count beer_count heart_count biceps_count orz_count confused_count pill_count)a

  @default_emotions %{
    # downvote
    downvote_count: 0,
    latest_downvote_users: [],
    # beer
    beer_count: 0,
    latest_beer_users: [],
    # heart
    heart_count: 0,
    latest_heart_users: [],
    # biceps
    biceps_count: 0,
    latest_biceps_users: [],
    # orz
    orz_count: 0,
    latest_orz_users: [],
    # confused
    confused_count: 0,
    latest_confused_users: [],
    # pill
    pill_count: 0,
    latest_pill_users: []
  }

  @doc "for test usage"
  def default_emotions(), do: @default_emotions

  embedded_schema do
    # downvote
    field(:downvote_count, :integer, default: 0)
    embeds_many(:latest_downvote_users, Embeds.User, on_replace: :delete)
    # beer
    field(:beer_count, :integer, default: 0)
    embeds_many(:latest_beer_users, Embeds.User, on_replace: :delete)
    # heart
    field(:heart_count, :integer, default: 0)
    embeds_many(:latest_heart_users, Embeds.User, on_replace: :delete)
    # biceps
    field(:biceps_count, :integer, default: 0)
    embeds_many(:latest_biceps_users, Embeds.User, on_replace: :delete)
    # orz
    field(:orz_count, :integer, default: 0)
    embeds_many(:latest_orz_users, Embeds.User, on_replace: :delete)
    # confused
    field(:confused_count, :integer, default: 0)
    embeds_many(:latest_confused_users, Embeds.User, on_replace: :delete)
    # pill
    field(:pill_count, :integer, default: 0)
    embeds_many(:latest_pill_users, Embeds.User, on_replace: :delete)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
    |> cast_embed(:latest_downvote_users, required: false, with: &Embeds.User.changeset/2)
    |> cast_embed(:latest_beer_users, required: false, with: &Embeds.User.changeset/2)
    |> cast_embed(:latest_heart_users, required: false, with: &Embeds.User.changeset/2)
    |> cast_embed(:latest_biceps_users, required: false, with: &Embeds.User.changeset/2)
    |> cast_embed(:latest_orz_users, required: false, with: &Embeds.User.changeset/2)
    |> cast_embed(:latest_confused_users, required: false, with: &Embeds.User.changeset/2)
    |> cast_embed(:latest_pill_users, required: false, with: &Embeds.User.changeset/2)
  end
end
