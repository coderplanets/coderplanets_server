defmodule GroupherServer.CMS.Model.Embeds.ArticleEmotion.Macros do
  @moduledoc """
  general fields for each emotion

  e.g:
    field(:beer_count, :integer, default: 0)
    field(:beer_user_logins, :string)
    field(:viewer_has_beered, :boolean, default: false, virtual: true)
    embeds_many(:latest_beer_users, Embeds.User, on_replace: :delete)
  """
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias CMS.Model.Embeds

  @supported_emotions get_config(:article, :emotions)

  defmacro emotion_fields() do
    @supported_emotions
    |> Enum.map(fn emotion ->
      quote do
        field(unquote(:"#{emotion}_count"), :integer, default: 0)
        field(unquote(:"#{emotion}_user_logins"), {:array, :string}, default: [])
        field(unquote(:"viewer_has_#{emotion}ed"), :boolean, default: false, virtual: true)
        embeds_many(unquote(:"latest_#{emotion}_users"), Embeds.User, on_replace: :delete)
      end
    end)
  end
end

defmodule GroupherServer.CMS.Model.Embeds.ArticleEmotion do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Model.Embeds.ArticleEmotion.Macros
  import Helper.Utils, only: [get_config: 2]

  @supported_emotions get_config(:article, :emotions)

  @optional_fields Enum.map(@supported_emotions, &:"#{&1}_count") ++
                     Enum.map(@supported_emotions, &:"#{&1}_user_logins")

  @doc "default emotion status for article comment"
  # for create comment and test usage
  def default_emotions() do
    @supported_emotions
    |> Enum.reduce([], fn emotion, acc ->
      acc ++
        [
          "#{emotion}_count": 0,
          "latest_#{emotion}_users": [],
          "#{emotion}_user_logins": [],
          "viewer_has_#{emotion}ed": false
        ]
    end)
    |> Enum.into(%{})
  end

  embedded_schema do
    emotion_fields()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)

    # |> cast_embed(:latest_downvote_users, required: false, with: &Embeds.User.changeset/2)
    # |> ...
  end
end
