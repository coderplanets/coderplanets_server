defmodule GroupherServer.CMS.ArticleUpvote do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.User
  alias CMS.{Post, Job, Repo}

  @required_fields ~w(user_id)a
  @optional_fields ~w(thread post_id job_id repo_id)a

  @type t :: %ArticleUpvote{}
  schema "article_upvotes" do
    # for user-center to filter
    field(:thread, :string)

    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:repo, Repo, foreign_key: :repo_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleUpvote{} = article_upvote, attrs) do
    article_upvote
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:repo_id)
  end
end
