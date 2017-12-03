#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Ordering.Item do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :price, :decimal
    field :name, :string
    field :quantity, :integer
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:price, :name, :quantity])
    |> validate_required([:price, :name, :quantity])
  end
end
