#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Ordering.Order do
  use Ecto.Schema
  import Ecto.Changeset
  alias PlateSlate.Ordering.Order

  schema "orders" do
    field :customer_number, :integer
    field :ordered_at, :utc_datetime, read_after_writes: true
    field :state, :string, read_after_writes: true

    embeds_many :items, PlateSlate.Ordering.Item

    timestamps()
  end

  @doc false
  def changeset(%Order{} = order, attrs) do
    order
    |> cast(attrs, [:customer_number, :ordered_at, :state])
    |> validate_required([:customer_number])
    |> cast_embed(:items)
  end
end
