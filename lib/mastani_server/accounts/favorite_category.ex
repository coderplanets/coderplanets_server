defmodule MastaniServer.Accounts.FavoriteCategory do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.User

  @required_fields ~w(user_id title)a
  @optional_fields ~w(index total_count private desc last_updated)a

  @type t :: %FavoriteCategory{}
  schema "favorite_categories" do
    belongs_to(:user, User, foreign_key: :user_id)
    # has_many(:posts, ...)

    field(:title, :string)
    field(:desc, :string)
    field(:index, :integer)
    field(:total_count, :integer, default: 0)
    field(:private, :boolean, default: false)
    # last time when add/delete items in category
    field(:last_updated, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%FavoriteCategory{} = favorite_category, attrs) do
    favorite_category
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 1)
    |> foreign_key_constraint(:user_id)
  end
end
