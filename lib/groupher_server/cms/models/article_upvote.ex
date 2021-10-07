defmodule GroupherServer.CMS.Model.ArticleUpvote do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Helper.Macros

  import GroupherServer.CMS.Helper.Utils,
    only: [articles_foreign_key_constraint: 1, articles_upvote_unique_key_constraint: 1]

  alias GroupherServer.Accounts
  alias Accounts.Model.User

  @article_threads get_config(:article, :threads)

  @required_fields ~w(user_id)a
  @optional_fields ~w(thread)a
  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @type t :: %ArticleUpvote{}
  schema "article_upvotes" do
    # for user-center to filter
    field(:thread, :string)
    belongs_to(:user, User, foreign_key: :user_id)

    article_belongs_to_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleUpvote{} = article_upvote, attrs) do
    article_upvote
    |> cast(attrs, @optional_fields ++ @required_fields ++ @article_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> articles_upvote_unique_key_constraint
    |> articles_foreign_key_constraint
  end
end
