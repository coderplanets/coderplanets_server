defmodule MastaniServer.CMS.Category do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Author, Community}
  # alias MastaniServer.Accounts
  # alias Helper.Certification

  @required_fields ~w(title raw author_id)a

  @type t :: %Category{}

  schema "categories" do
    field(:title, :string)
    field(:raw, :string)
    belongs_to(:author, Author)

    many_to_many(
      :communities,
      Community,
      join_through: "communities_categories",
      join_keys: [category_id: :id, community_id: :id],
      on_delete: :delete_all,
      on_replace: :delete
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    # |> validate_inclusion(:title, Certification.editor_titles(:cms))
    # |> foreign_key_constraint(:community_id)
    # |> foreign_key_constraint(:author_id)
    |> unique_constraint(:title, name: :categories_title_index)
  end
end
