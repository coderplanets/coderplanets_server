defmodule GroupherServer.CMS.ArticlePinedComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.CMS

  alias CMS.{
    Post,
    Job,
    ArticleComment
  }

  # alias Helper.HTML

  @required_fields ~w(article_comment_id)a
  @optional_fields ~w(post_id job_id)a

  @type t :: %ArticlePinedComment{}
  schema "articles_pined_comments" do
    belongs_to(:article_comment, ArticleComment, foreign_key: :article_comment_id)
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticlePinedComment{} = article_pined_comment, attrs) do
    article_pined_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  # @doc false
  def update_changeset(%ArticlePinedComment{} = article_pined_comment, attrs) do
    article_pined_comment
    |> cast(attrs, @required_fields ++ @updatable_fields)
  end
end
