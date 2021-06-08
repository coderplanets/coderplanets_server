defmodule GroupherServer.Accounts.Model.CollectFolder do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.{User, Embeds}
  alias CMS.Model.ArticleCollect

  @required_fields ~w(user_id title)a
  @optional_fields ~w(index total_count private desc last_updated)a

  @type t :: %CollectFolder{}
  schema "collect_folders" do
    belongs_to(:user, User, foreign_key: :user_id)
    # has_many(:posts, ...)

    field(:title, :string)
    field(:desc, :string)
    field(:index, :integer)
    field(:total_count, :integer, default: 0)
    field(:private, :boolean, default: false)
    # last time when add/delete items in category
    field(:last_updated, :utc_datetime)

    # 可以参照 fragment 查询语法啊
    # 2. article truple [{:post, 1}, [:job, 2]] ... 便于在计算 "成就" 的时候对比
    embeds_one(:meta, Embeds.CollectFolderMeta, on_replace: :delete)
    embeds_many(:collects, ArticleCollect, on_replace: :delete)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CollectFolder{} = collect_folder, attrs) do
    collect_folder
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: true, with: &Embeds.CollectFolderMeta.changeset/2)
    |> validate_length(:title, min: 1)
    |> foreign_key_constraint(:user_id)
  end

  @doc false
  def update_changeset(%CollectFolder{} = collect_folder, attrs) do
    collect_folder
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast_embed(:collects, with: &ArticleCollect.changeset/2)
    |> cast_embed(:meta, with: &Embeds.CollectFolderMeta.changeset/2)
    |> validate_length(:title, min: 1)
    |> foreign_key_constraint(:user_id)
  end
end
