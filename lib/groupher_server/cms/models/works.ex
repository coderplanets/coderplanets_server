defmodule GroupherServer.CMS.Model.Works do
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
  @optional_fields @article_cast_fields

  @type t :: %Works{}
  schema "cms_works" do
    article_tags_field(:works)
    article_communities_field(:works)
    general_article_fields(:works)
  end

  @doc false
  def changeset(%Works{} = works, attrs) do
    works
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Works{} = works, attrs) do
    works
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> generl_changeset
  end

  defp generl_changeset(changeset) do
    changeset
    |> validate_length(:title, min: 3, max: 100)
    |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
  end
end
