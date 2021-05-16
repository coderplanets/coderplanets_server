defmodule GroupherServer.CMS.ArticleUpvote do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.User

  @article_threads CMS.Community.article_threads()

  @required_fields ~w(user_id)a
  @optional_fields ~w(thread)a
  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @type t :: %ArticleUpvote{}
  schema "article_upvotes" do
    # for user-center to filter
    field(:thread, :string)
    belongs_to(:user, User, foreign_key: :user_id)

    article_belongs_to()

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleUpvote{} = article_upvote, attrs) do
    article_upvote
    |> cast(attrs, @optional_fields ++ @required_fields ++ @article_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)

    # |> foreign_key_constraint(:post_id)
    # |> foreign_key_constraint(:job_id)
    # |> foreign_key_constraint(:repo_id)
  end
end
