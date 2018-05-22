defmodule MastaniServer.CMS.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Community, Category}
  # alias MastaniServer.Accounts
  # alias Helper.Certification

  @required_fields ~w(title user_id)a

  schema "categories" do
    field(:title, :string)
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    # |> validate_inclusion(:title, Certification.editor_titles(:cms))
    # |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:title, name: :categories_title_index)
  end
end
