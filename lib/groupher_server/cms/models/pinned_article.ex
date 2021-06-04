defmodule GroupherServer.CMS.Model.PinnedArticle do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Helper.Macros
  import GroupherServer.CMS.Helper.Utils, only: [articles_foreign_key_constraint: 1]

  alias GroupherServer.CMS
  alias CMS.Model.Community

  @article_threads get_config(:article, :threads)

  @required_fields ~w(community_id thread)a
  # @optional_fields ~w(post_id job_id repo_id)a
  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @type t :: %PinnedArticle{}
  schema "pinned_articles" do
    belongs_to(:community, Community, foreign_key: :community_id)
    field(:thread, :string)

    article_belongs_to_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PinnedArticle{} = pinned_article, attrs) do
    pinned_article
    |> cast(attrs, @article_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:community_id)
    |> articles_foreign_key_constraint
  end
end
