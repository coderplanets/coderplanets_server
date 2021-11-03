defmodule GroupherServer.CMS.Model.Blog do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Model.Embeds

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(title digest)a
  @article_cast_fields general_article_cast_fields()
  @optional_fields ~w(digest feed_digest feed_content published rss)a ++ @article_cast_fields

  @type t :: %Blog{}
  schema "cms_blogs" do
    # for frontend constant
    field(:copy_right, :string, default: "", virtual: true)
    field(:rss, :string)

    field(:feed_digest, :string)
    field(:feed_content, :string)
    field(:published, :string)
    embeds_one(:blog_author, Embeds.BlogAuthor, on_replace: :update)

    article_tags_field(:blog)
    article_communities_field(:blog)
    general_article_fields(:blog)
  end

  @doc false
  def changeset(%Blog{} = blog, attrs) do
    blog
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> cast_embed(:blog_author, required: false, with: &Embeds.BlogAuthor.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Blog{} = blog, attrs) do
    blog
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast_embed(:blog_author, required: false, with: &Embeds.BlogAuthor.changeset/2)
    |> generl_changeset
  end

  defp generl_changeset(changeset) do
    changeset
    |> validate_length(:title, min: 3, max: 100)
    |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
    |> validate_length(:link_addr, min: 5, max: 400)
  end
end
