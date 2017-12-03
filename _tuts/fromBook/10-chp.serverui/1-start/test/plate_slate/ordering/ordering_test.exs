#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.OrderingTest do
  use PlateSlate.DataCase, async: true

  alias PlateSlate.Ordering

  setup do
    Code.load_file("priv/repo/seeds.exs")
  end

  describe "orders" do
    alias PlateSlate.Ordering.Order

    test "create_order/1 with valid data creates a order" do
      chai = Repo.get_by!(PlateSlate.Menu.Item, name: "Masala Chai")
      fries = Repo.get_by!(PlateSlate.Menu.Item, name: "French Fries")

      attrs = %{
        customer_number: 42,
        ordered_at: "2010-04-17 14:00:00.000000Z",
        state: "created",
        items: [
          %{menu_item_id: chai.id, quantity: 1},
          %{menu_item_id: fries.id, quantity: 2},
        ]
      }

      assert {:ok, %Order{} = order} = Ordering.create_order(attrs)
      assert Enum.map(order.items,
        &Map.take(&1, [:name, :quantity, :price])
      ) == [
        %{name: "Masala Chai", quantity: 1, price: chai.price},
        %{name: "French Fries", quantity: 2, price: fries.price},
      ]

      assert order.state == "created"
    end
  end
end
