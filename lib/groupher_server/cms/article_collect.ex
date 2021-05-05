defmodule GroupherServer.CMS.ArticleCollect do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.{User, CollectFolder}
  alias CMS.{Post, Job, Repo}

  @required_fields ~w(user_id)a
  @optional_fields ~w(thread post_id job_id repo_id)a

  @type t :: %ArticleCollect{}
  schema "article_collects" do
    field(:thread, :string)

    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:repo, Repo, foreign_key: :repo_id)

    embeds_many(:collect_folders, CollectFolder, on_replace: :delete)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleCollect{} = article_collect, attrs) do
    article_collect
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:collect_folders, with: &CollectFolder.changeset/2)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:repo_id)
  end
end
