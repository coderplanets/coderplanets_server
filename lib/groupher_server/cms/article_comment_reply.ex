defmodule GroupherServer.CMS.ArticleCommentReply do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.ArticleComment

  @required_fields ~w(article_comment_id reply_to_id)a

  @type t :: %ArticleCommentReply{}
  schema "articles_comments_replies" do
    belongs_to(:article_comment, ArticleComment, foreign_key: :article_comment_id)
    belongs_to(:reply_to, ArticleComment, foreign_key: :reply_to_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleCommentReply{} = article_comment_reply, attrs) do
    article_comment_reply
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:article_comment_id)
    |> foreign_key_constraint(:reply_to_id)
  end
end
