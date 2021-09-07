defmodule GroupherServer.CMS.Model.Job do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Model.Embeds

  @timestamps_opts [type: :utc_datetime_usec]
  @required_fields ~w(title company digest)a
  @article_cast_fields general_article_cast_fields()
  @optional_fields @article_cast_fields ++ ~w(desc company_link copy_right)a

  @type t :: %Job{}
  schema "cms_jobs" do
    field(:company, :string)
    field(:company_link, :string)
    field(:desc, :string)

    field(:copy_right, :string)

    article_tags_field(:job)
    article_communities_field(:job)
    general_article_fields(:job)
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
    |> validate_length(:title, min: 3, max: 100)
  end
end
