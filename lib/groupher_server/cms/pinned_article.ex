defmodule GroupherServer.CMS.PinnedArticle do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Community

  @article_threads CMS.Community.article_threads()

  @required_fields ~w(community_id thread)a
  # @optional_fields ~w(post_id job_id repo_id)a
  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @type t :: %PinnedArticle{}
  schema "pinned_articles" do
    belongs_to(:community, Community, foreign_key: :community_id)
    field(:thread, :string)

    article_belongs_to()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PinnedArticle{} = pinned_article, attrs) do
    pinned_article
    |> cast(attrs, @article_fields ++ @required_fields)
    |> validate_required(@required_fields)
    # |> foreign_key_constraint(:post_id)
    # |> foreign_key_constraint(:job_id)
    # |> foreign_key_constraint(:repo_id)
    |> foreign_key_constraint(:community_id)

    # |> unique_constraint(:pinned_articles, name: :pinned_articles_post_id_community_id_index)
  end
end
