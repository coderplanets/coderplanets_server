defmodule GroupherServer.CMS.Embeds.ArticleCommentEmotion do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.CMS.Embeds

  @supported_emotions [:downvote, :beer, :heart, :biceps, :orz, :confused, :pill]

  @optional_fields Enum.map(@supported_emotions, &:"#{&1}_count") ++
                     Enum.map(@supported_emotions, &:"#{&1}_user_logins")

  @doc "for test usage"
  def default_emotions() do
    @supported_emotions
    |> Enum.reduce([], fn emotion, acc ->
      acc ++
        [
          "#{emotion}_count": 0,
          "latest_#{emotion}_users": [],
          "#{emotion}_user_logins": "",
          "viewer_has_#{emotion}ed": false
        ]
    end)
    |> Enum.into(%{})
  end

  def supported_emotions(), do: @supported_emotions

  embedded_schema do
    # downvote
    field(:downvote_count, :integer, default: 0)
    embeds_many(:latest_downvote_users, Embeds.User, on_replace: :delete)
    field(:downvote_user_logins, :string)
    field(:viewer_has_downvoteed, :boolean, default: false, virtual: true)

    # beer
    field(:beer_count, :integer, default: 0)
    embeds_many(:latest_beer_users, Embeds.User, on_replace: :delete)
    field(:beer_user_logins, :string)
    field(:viewer_has_beered, :boolean, default: false, virtual: true)
    # heart
    field(:heart_count, :integer, default: 0)
    embeds_many(:latest_heart_users, Embeds.User, on_replace: :delete)
    field(:heart_user_logins, :string)
    field(:viewer_has_hearted, :boolean, default: false, virtual: true)
    # biceps
    field(:biceps_count, :integer, default: 0)
    embeds_many(:latest_biceps_users, Embeds.User, on_replace: :delete)
    field(:biceps_user_logins, :string)
    field(:viewer_has_bicepsed, :boolean, default: false, virtual: true)
    # orz
    field(:orz_count, :integer, default: 0)
    embeds_many(:latest_orz_users, Embeds.User, on_replace: :delete)
    field(:orz_user_logins, :string)
    field(:viewer_has_orzed, :boolean, default: false, virtual: true)
    # confused
    field(:confused_count, :integer, default: 0)
    embeds_many(:latest_confused_users, Embeds.User, on_replace: :delete)
    field(:confused_user_logins, :string)
    field(:viewer_has_confuseded, :boolean, default: false, virtual: true)
    # pill
    field(:pill_count, :integer, default: 0)
    embeds_many(:latest_pill_users, Embeds.User, on_replace: :delete)
    field(:pill_user_logins, :string)
    field(:viewer_has_pilled, :boolean, default: false, virtual: true)
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
