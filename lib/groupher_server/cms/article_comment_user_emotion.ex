defmodule GroupherServer.CMS.ArticleCommentUserEmotion.Macros do
  alias GroupherServer.CMS
  alias CMS.ArticleComment

  @supported_emotions ArticleComment.supported_emotions()

  defmacro emotion_fields() do
    @supported_emotions
    |> Enum.map(fn emotion ->
      quote do
        field(unquote(:"#{emotion}"), :boolean, default: false)
      end
    end)
  end
end

defmodule GroupherServer.CMS.ArticleCommentUserEmotion do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.CMS.ArticleCommentUserEmotion.Macros

  alias GroupherServer.{Accounts, CMS}
  alias CMS.ArticleComment

  @supported_emotions ArticleComment.supported_emotions()

  @required_fields ~w(article_comment_id user_id recived_user_id)a
  # @optional_fields ~w(downvote beer heart biceps orz confused pill)a
  @optional_fields Enum.map(@supported_emotions, &:"#{&1}")

  @type t :: %ArticleCommentUserEmotion{}
  schema "articles_comments_users_emotions" do
    belongs_to(:article_comment, ArticleComment, foreign_key: :article_comment_id)
    belongs_to(:recived_user, Accounts.User, foreign_key: :recived_user_id)
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    emotion_fields()
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

  def update_changeset(%ArticleCommentUserEmotion{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:article_comment_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:recived_user_id)
  end
end
