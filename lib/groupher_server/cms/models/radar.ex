defmodule GroupherServer.CMS.Model.Radar do
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
  @optional_fields ~w(copy_right)a ++ @article_cast_fields

  @type t :: %Radar{}
  schema "cms_radars" do
    field(:copy_right, :string, default: "", virtual: true)

    article_tags_field(:radar)
    article_communities_field(:radar)
    general_article_fields(:radar)
  end

  @doc false
  def changeset(%Radar{} = radar, attrs) do
    radar
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Radar{} = radar, attrs) do
    radar
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> generl_changeset
  end

  defp generl_changeset(changeset) do
    changeset
    |> validate_length(:title, min: 3, max: 100)
    |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
  end
end
