defmodule GroupherServer.CMS.Model.ArticleCollect do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Helper.Macros
  import GroupherServer.CMS.Helper.Utils, only: [articles_foreign_key_constraint: 1]

  alias GroupherServer.Accounts
  alias Accounts.Model.{User, CollectFolder}

  @article_threads get_config(:article, :threads)

  @required_fields ~w(user_id)a
  @optional_fields ~w(thread)a

  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @type t :: %ArticleCollect{}
  schema "article_collects" do
    field(:thread, :string)
    belongs_to(:user, User, foreign_key: :user_id)
    embeds_many(:collect_folders, CollectFolder, on_replace: :delete)

    article_belongs_to_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%ArticleCollect{} = article_collect, attrs) do
    article_collect
    |> cast(attrs, @optional_fields ++ @required_fields ++ @article_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:collect_folders, with: &CollectFolder.changeset/2)
    |> foreign_key_constraint(:user_id)
    |> articles_foreign_key_constraint
  end
end
