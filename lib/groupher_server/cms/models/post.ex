defmodule GroupherServer.CMS.Model.Post do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Model.Embeds

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(title digest)a
  @article_cast_fields general_article_cast_fields()
  @optional_fields ~w(copy_right is_question is_solved solution_digest updated_at inserted_at active_at archived_at)a ++
                     @article_cast_fields

  @type t :: %Post{}
  schema "cms_posts" do
    field(:copy_right, :string)

    field(:is_question, :boolean, default: false)
    field(:is_solved, :boolean, default: false)
    field(:solution_digest, :string)

    # TODO: remove
    field(:body, :string)

    article_tags_field(:post)
    article_communities_field(:post)
    general_article_fields(:post)
  end

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> generl_changeset
  end

  defp generl_changeset(changeset) do
    changeset
    |> validate_length(:title, min: 3, max: 100)
    |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
    |> validate_length(:link_addr, min: 5, max: 400)
    |> HTML.safe_string(:body)
  end
end
