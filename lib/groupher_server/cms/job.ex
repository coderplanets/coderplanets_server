defmodule GroupherServer.CMS.Job do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Embeds
  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]
  @required_fields ~w(title company company_logo body digest length)a
  @article_cast_fields general_article_fields(:cast)
  @optional_fields @article_cast_fields ++
                     ~w(desc company_link link_addr copy_right salary exp education field finance scale)a

  @type t :: %Job{}
  schema "cms_jobs" do
    field(:title, :string)
    field(:company, :string)
    field(:company_logo, :string)
    field(:company_link, :string)
    field(:desc, :string)
    field(:body, :string)

    field(:link_addr, :string)
    field(:copy_right, :string)

    field(:salary, :string)
    field(:exp, :string)
    field(:education, :string)
    field(:field, :string)
    field(:finance, :string)
    field(:scale, :string)

    field(:digest, :string)
    field(:length, :integer)

    article_tags_field(:job)
    article_community_field(:job)
    general_article_fields()
  end

  @doc false
  def changeset(%Job{} = job, attrs) do
    job
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Job{} = job, attrs) do
    job
    |> cast(attrs, @optional_fields ++ @required_fields)
    # |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> validate_length(:title, min: 3, max: 50)
    |> validate_length(:body, min: 3, max: 10_000)
    # |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
    |> HTML.safe_string(:body)
  end
end
