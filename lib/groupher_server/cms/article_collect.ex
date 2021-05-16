defmodule GroupherServer.CMS.ArticleCollect do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.{User, CollectFolder}

  @article_threads CMS.Community.article_threads()

  @required_fields ~w(user_id)a
  @optional_fields ~w(thread)a

  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @type t :: %ArticleCollect{}
  schema "article_collects" do
    field(:thread, :string)
    belongs_to(:user, User, foreign_key: :user_id)
    embeds_many(:collect_folders, CollectFolder, on_replace: :delete)

    article_belongs_to()

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleCollect{} = article_collect, attrs) do
    article_collect
    |> cast(attrs, @optional_fields ++ @required_fields ++ @article_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:collect_folders, with: &CollectFolder.changeset/2)
    |> foreign_key_constraint(:user_id)

    # |> foreign_key_constraint(:post_id)
    # |> foreign_key_constraint(:job_id)
    # |> foreign_key_constraint(:repo_id)
  end
end
