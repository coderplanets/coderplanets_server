defmodule GroupherServer.CMS.Model.ArticleTag do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.Model.{Author, Community}

  @required_fields ~w(thread title color author_id community_id raw)a
  @updatable_fields ~w(thread title color community_id group extra icon raw)a

  @type t :: %ArticleTag{}
  schema "article_tags" do
    field(:title, :string)
    field(:raw, :string)
    field(:color, :string)
    field(:thread, :string)
    field(:group, :string)
    field(:extra, {:array, :string})
    field(:icon, :string)

    belongs_to(:community, Community)
    belongs_to(:author, Author)

    timestamps(type: :utc_datetime)
  end

  def changeset(%ArticleTag{} = tag, attrs) do
    tag
    |> cast(attrs, @required_fields ++ @updatable_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:community_id)
  end

  def update_changeset(%ArticleTag{} = tag, attrs) do
    tag
    |> cast(attrs, @updatable_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:community_id)
  end
end
