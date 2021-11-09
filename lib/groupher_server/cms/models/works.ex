defmodule GroupherServer.CMS.Model.Works do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.{CMS, Accounts}
  alias CMS.Model.{Embeds, Techstack, City}
  alias Accounts.Model.User

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(cover title digest)a
  @article_cast_fields general_article_cast_fields()
  @optional_fields ~w(desc home_link profit_mode working_mode community_link interview_link)a ++
                     @article_cast_fields

  @type t :: %Works{}
  schema "cms_works" do
    field(:cover, :string)
    field(:home_link, :string)
    field(:desc, :string)
    # ...
    field(:profit_mode, :string)
    # fulltime / parttime
    field(:working_mode, :string)

    embeds_many(:social_info, Embeds.SocialInfo, on_replace: :delete)
    embeds_many(:app_store, Embeds.AppStore, on_replace: :delete)
    # embeds_many(:teamate, Embeds.Teammate, on_replace: :delete)

    field(:community_link, :string)
    field(:interview_link, :string)

    many_to_many(
      :techstacks,
      Techstack,
      join_through: "works_join_techstacks",
      on_replace: :delete
    )

    many_to_many(
      :teammates,
      User,
      join_through: "works_join_teammates",
      on_replace: :delete
    )

    many_to_many(
      :cities,
      City,
      join_through: "works_join_cities",
      on_replace: :delete
    )

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
    |> cast_embed(:social_info, required: false, with: &Embeds.SocialInfo.changeset/2)
    |> cast_embed(:app_store, required: false, with: &Embeds.AppStore.changeset/2)
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
