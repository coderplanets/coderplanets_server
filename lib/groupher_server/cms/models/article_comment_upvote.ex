defmodule GroupherServer.CMS.Model.ArticleCommentUpvote do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.ArticleComment

  @required_fields ~w(article_comment_id user_id)a

  @type t :: %ArticleCommentUpvote{}
  schema "articles_comments_upvotes" do
    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:article_comment, ArticleComment, foreign_key: :article_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleCommentUpvote{} = article_comment_upvote, attrs) do
    article_comment_upvote
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:article_comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id,
      name: :articles_comments_upvotes_user_id_article_comment_id_index
    )
  end
end
