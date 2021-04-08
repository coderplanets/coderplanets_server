defmodule GroupherServer.CMS.ArticleComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias CMS.{
    Post,
    Job,
    ArticleCommentUpvote
  }

  # alias Helper.HTML

  @required_fields ~w(body_html author_id)a
  @optional_fields ~w(post_id job_id)a

  @type t :: %ArticleComment{}
  schema "articles_comments" do
    field(:body_html, :string)
    # field(:floor, :integer)

    belongs_to(:author, Accounts.User, foreign_key: :author_id)
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)

    has_many(:upvotes, {"articles_comments_upvotes", ArticleCommentUpvote})

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          GroupherServer.CMS.ArticleComment.t(),
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(%ArticleComment{} = article_comment, attrs) do
    article_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)

    # |> generl_changeset
  end

  # @doc false
  # def update_changeset(%PostComment{} = post_comment, attrs) do
  #   post_comment
  #   |> cast(attrs, @required_fields ++ @optional_fields)
  #   |> generl_changeset
  # end

  # defp generl_changeset(content) do
  #   content
  #   |> foreign_key_constraint(:post_id)
  #   |> foreign_key_constraint(:author_id)
  #   |> validate_length(:body_html, min: 3, max: 2000)
  #   |> HTML.safe_string(:body_html)
  # end
end
