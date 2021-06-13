defmodule GroupherServer.CMS.Model.CommentUserEmotion.Macros do
  import Helper.Utils, only: [get_config: 2]

  @supported_emotions get_config(:article, :comment_emotions)

  defmacro emotion_fields() do
    @supported_emotions
    |> Enum.map(fn emotion ->
      quote do
        field(unquote(:"#{emotion}"), :boolean, default: false)
      end
    end)
  end
end

defmodule GroupherServer.CMS.Model.CommentUserEmotion do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.CMS.Model.CommentUserEmotion.Macros
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.Comment

  @supported_emotions get_config(:article, :comment_emotions)

  @required_fields ~w(comment_id user_id recived_user_id)a
  @optional_fields Enum.map(@supported_emotions, &:"#{&1}")

  @type t :: %CommentUserEmotion{}
  schema "comments_users_emotions" do
    belongs_to(:comment, Comment, foreign_key: :comment_id)
    belongs_to(:recived_user, User, foreign_key: :recived_user_id)
    belongs_to(:user, User, foreign_key: :user_id)

    emotion_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommentUserEmotion{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:comment_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:recived_user_id)
  end

  def update_changeset(%CommentUserEmotion{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:omment_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:recived_user_id)
  end
end
