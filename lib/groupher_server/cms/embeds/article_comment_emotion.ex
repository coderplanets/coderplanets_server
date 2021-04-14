defmodule GroupherServer.CMS.Embeds.ArticleCommentEmotion do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS.Embeds

  @optional_fields ~w(downvote_count downvote_user_ids beer_count beer_user_ids heart_count heart_user_ids biceps_count biceps_user_ids orz_count orz_user_ids confused_count confused_user_ids pill_count pill_user_ids)a

  @default_emotions %{
    # downvote
    downvote_count: 0,
    latest_downvote_users: [],
    downvote_user_ids: "",
    viewer_has_downvoted: false,
    # beer
    beer_count: 0,
    latest_beer_users: [],
    beer_user_ids: "",
    # heart
    heart_count: 0,
    latest_heart_users: [],
    heart_user_ids: "",
    # biceps
    biceps_count: 0,
    latest_biceps_users: [],
    biceps_user_ids: "",
    # orz
    orz_count: 0,
    latest_orz_users: [],
    orz_user_ids: "",
    # confused
    confused_count: 0,
    latest_confused_users: [],
    confused_user_ids: "",
    # pill
    pill_count: 0,
    latest_pill_users: [],
    pill_user_ids: ""
  }

  @doc "for test usage"
  def default_emotions(), do: @default_emotions

  embedded_schema do
    # downvote
    field(:downvote_count, :integer, default: 0)
    embeds_many(:latest_downvote_users, Embeds.User, on_replace: :delete)
    field(:downvote_user_ids, :string)
    field(:viewer_has_downvoted, :boolean, default: false, virtual: true)

    # beer
    field(:beer_count, :integer, default: 0)
    embeds_many(:latest_beer_users, Embeds.User, on_replace: :delete)
    field(:beer_user_ids, :string)
    # heart
    field(:heart_count, :integer, default: 0)
    embeds_many(:latest_heart_users, Embeds.User, on_replace: :delete)
    field(:heart_user_ids, :string)
    # biceps
    field(:biceps_count, :integer, default: 0)
    embeds_many(:latest_biceps_users, Embeds.User, on_replace: :delete)
    field(:biceps_user_ids, :string)
    # orz
    field(:orz_count, :integer, default: 0)
    embeds_many(:latest_orz_users, Embeds.User, on_replace: :delete)
    field(:orz_user_ids, :string)
    # confused
    field(:confused_count, :integer, default: 0)
    embeds_many(:latest_confused_users, Embeds.User, on_replace: :delete)
    field(:confused_user_ids, :string)
    # pill
    field(:pill_count, :integer, default: 0)
    embeds_many(:latest_pill_users, Embeds.User, on_replace: :delete)
    field(:pill_user_ids, :string)
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
