#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Menu.ItemTag do
  use Ecto.Schema
  import Ecto.Changeset
  alias PlateSlate.Menu.ItemTag


  schema "item_tags" do
    field :description
    field :name, :string, null: false

    many_to_many :items, PlateSlate.Menu.Item, join_through: "items_taggings"

    timestamps()
  end

  @doc false
  def changeset(%ItemTag{} = item_tag, attrs) do
    item_tag
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
