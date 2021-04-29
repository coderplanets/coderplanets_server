defmodule GroupherServer.CMS.PinnedArticle do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.{Community, Post, Job, Repo}

  @required_fields ~w(community_id thread)a
  @optional_fields ~w(post_id job_id repo_id)a

  @type t :: %PinnedArticle{}
  schema "pinned_articles" do
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:repo, Repo, foreign_key: :repo_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    field(:thread, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PinnedArticle{} = pinned_article, attrs) do
    pinned_article
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:repo_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:pinned_articles, name: :pinned_articles_post_id_community_id_index)

    # |> unique_constraint(:pinned_articles, name: :pinned_articles_job_id_community_id_index)
    # |> unique_constraint(:pinned_articles, name: :pinned_articles_repo_id_community_id_index)
  end
end
