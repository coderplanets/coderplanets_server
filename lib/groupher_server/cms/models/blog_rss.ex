defmodule GroupherServer.CMS.Model.BlogRSS do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  # import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Model.Embeds

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(link rss)a
  @optional_fields ~w(subtitle author updated)a

  @type t :: %BlogRSS{}
  schema "cms_blog_rss" do
    field(:rss, :string)
    field(:title, :string)
    field(:subtitle, :string)
    field(:link, :string)
    field(:updated, :string)
    embeds_many(:history_feed, Embeds.BlogHistoryFeed, on_replace: :delete)
    embeds_one(:author, Embeds.BlogAuthor, on_replace: :update)
  end

  @doc false
  def changeset(%BlogRSS{} = blog_rss, attrs) do
    blog_rss
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:history_feed, required: true, with: &Embeds.BlogHistoryFeed.changeset/2)
    |> cast_embed(:author, required: false, with: &Embeds.BlogAuthor.changeset/2)
  end

  @doc false
  def update_changeset(%BlogRSS{} = blog_rss, attrs) do
    blog_rss
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast_embed(:history_feed, required: false, with: &Embeds.BlogHistoryFeed.changeset/2)
    |> cast_embed(:author, required: false, with: &Embeds.BlogAuthor.changeset/2)
  end

  # @doc false
  # def update_changeset(%BlogRSS{} = blog_rss, attrs) do
  #   blog_rss
  #   |> cast(attrs, @optional_fields ++ @required_fields)
  #   |> generl_changeset
  # end

  # defp generl_changeset(changeset) do
  #   changeset
  #   |> validate_length(:title, min: 3, max: 100)
  #   |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
  #   |> validate_length(:link_addr, min: 5, max: 400)
  # end
end
