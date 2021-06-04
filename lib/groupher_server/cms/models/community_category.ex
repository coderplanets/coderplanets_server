defmodule GroupherServer.CMS.Model.CommunityCategory do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS

  alias CMS.Model.{Category, Community}

  @type t :: %CommunityCategory{}

  schema "communities_categories" do
    belongs_to(:community, Community, foreign_key: :community_id)
    belongs_to(:category, Category, foreign_key: :category_id)

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(community_id category_id)a

  @doc false
  def changeset(%CommunityCategory{} = community_category, attrs) do
    community_category
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:category_id)
    |> unique_constraint(
      :community_id,
      name: :communities_categories_community_id_category_id_index
    )
  end
end
