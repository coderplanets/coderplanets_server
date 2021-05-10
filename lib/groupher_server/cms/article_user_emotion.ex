defmodule GroupherServer.CMS.ArticleUserEmotion.Macros do
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS

  @supported_emotions get_config(:article, :supported_emotions)

  defmacro emotion_fields() do
    @supported_emotions
    |> Enum.map(fn emotion ->
      quote do
        field(unquote(:"#{emotion}"), :boolean, default: false)
      end
    end)
  end
end

defmodule GroupherServer.CMS.ArticleUserEmotion do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.CMS.ArticleUserEmotion.Macros
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{Accounts, CMS}
  alias CMS.{Post, Job}

  @supported_emotions get_config(:article, :supported_emotions)
  @supported_threads get_config(:article, :emotionable_threads)

  @required_fields ~w(user_id recived_user_id)a
  @optional_fields Enum.map(@supported_threads, &:"#{&1}_id") ++
                     Enum.map(@supported_emotions, &:"#{&1}")

  @type t :: %ArticleUserEmotion{}
  schema "articles_users_emotions" do
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:recived_user, Accounts.User, foreign_key: :recived_user_id)
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    emotion_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleUserEmotion{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:recived_user_id)
  end

  def update_changeset(%ArticleUserEmotion{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:recived_user_id)
  end
end
