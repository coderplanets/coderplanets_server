defmodule GroupherServer.CMS.PinedArticle do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.{Community, Post, Job}

  @required_fields ~w(community_id)a
  @optional_fields ~w(post_id job_id)a

  @type t :: %PinedArticle{}
  schema "pined_articles" do
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PinedArticle{} = pined_article, attrs) do
    pined_article
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:community_id)

    # |> unique_constraint(:pined_posts, name: :pined_posts_post_id_community_id_index)
  end
end
