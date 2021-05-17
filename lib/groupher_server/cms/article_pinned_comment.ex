defmodule GroupherServer.CMS.ArticlePinnedComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros
  import GroupherServer.CMS.Helper.Utils, only: [articles_foreign_key_constraint: 1]

  alias GroupherServer.CMS
  alias CMS.ArticleComment

  # alias Helper.HTML
  @article_threads CMS.Community.article_threads()

  @required_fields ~w(article_comment_id)a
  # @optional_fields ~w(post_id job_id repo_id)a

  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @type t :: %ArticlePinnedComment{}
  schema "articles_pinned_comments" do
    belongs_to(:article_comment, ArticleComment, foreign_key: :article_comment_id)

    article_belongs_to_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticlePinnedComment{} = article_pined_comment, attrs) do
    article_pined_comment
    |> cast(attrs, @required_fields ++ @article_fields)
    |> validate_required(@required_fields)
    |> articles_foreign_key_constraint
  end

  # @doc false
  def update_changeset(%ArticlePinnedComment{} = article_pined_comment, attrs) do
    article_pined_comment
    |> cast(attrs, @required_fields ++ @article_fields)
    |> articles_foreign_key_constraint
  end
end
