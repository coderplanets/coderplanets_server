defmodule GroupherServer.CMS.ArticleCommentUserEmotion do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}
  alias CMS.ArticleComment

  @required_fields ~w(article_comment_id user_id recived_user_id)a
  @optional_fields ~w(downvote beer heart biceps orz confused pill)a

  @type t :: %ArticleCommentUserEmotion{}
  schema "articles_comments_users_emotions" do
    belongs_to(:article_comment, ArticleComment, foreign_key: :article_comment_id)
    belongs_to(:recived_user, Accounts.User, foreign_key: :recived_user_id)
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    field(:downvote, :boolean, default: false)
    field(:beer, :boolean, default: false)
    field(:heart, :boolean, default: false)
    field(:biceps, :boolean, default: false)
    field(:orz, :boolean, default: false)
    field(:confused, :boolean, default: false)
    field(:pill, :boolean, default: false)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleCommentUserEmotion{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:article_comment_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:recived_user_id)
  end
end
