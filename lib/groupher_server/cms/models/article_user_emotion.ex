defmodule GroupherServer.CMS.Model.ArticleUserEmotion.Macros do
  import Helper.Utils, only: [get_config: 2]

  @supported_emotions get_config(:article, :emotions)

  defmacro emotion_fields() do
    @supported_emotions
    |> Enum.map(fn emotion ->
      quote do
        field(unquote(:"#{emotion}"), :boolean, default: false)
      end
    end)
  end
end

defmodule GroupherServer.CMS.Model.ArticleUserEmotion do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.CMS.Model.ArticleUserEmotion.Macros
  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Helper.Macros
  import GroupherServer.CMS.Helper.Utils, only: [articles_foreign_key_constraint: 1]

  alias GroupherServer.Accounts
  alias Accounts.Model.User

  @supported_emotions get_config(:article, :emotions)
  @article_threads get_config(:article, :threads)

  @required_fields ~w(user_id recived_user_id)a
  @optional_fields Enum.map(@article_threads, &:"#{&1}_id") ++
                     Enum.map(@supported_emotions, &:"#{&1}")

  @type t :: %ArticleUserEmotion{}
  schema "articles_users_emotions" do
    belongs_to(:recived_user, User, foreign_key: :recived_user_id)
    belongs_to(:user, User, foreign_key: :user_id)

    emotion_fields()
    article_belongs_to_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleUserEmotion{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:recived_user_id)
    |> articles_foreign_key_constraint
  end

  def update_changeset(%ArticleUserEmotion{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:recived_user_id)
    |> articles_foreign_key_constraint
  end
end
