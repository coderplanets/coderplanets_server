#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.OrderingTypes do
  use Absinthe.Schema.Notation

  input_object :order_item_input do
    field :menu_item_id, non_null(:id)
    field :quantity, non_null(:integer)
  end

  input_object :place_order_input do
    field :customer_number, non_null(:integer)
    field :items, non_null(list_of(non_null(:order_item_input)))
  end

  object :customer do
    field :name, :string
    field :email, :string
    field :orders, list_of(:order) do
      resolve &PlateSlateWeb.Resolvers.Ordering.orders/3
    end
  end

  object :customer_session do
    field :token, :string
    field :customer, :customer
  end

  object :order_result do
    field :order, :order
    field :errors, list_of(:input_error)
  end

  object :order do
    field :id, :id
    field :customer_number, :integer
    field :items, list_of(:order_item)
    field :state, :string
  end

  object :order_item do
    field :name, :string
    field :quantity, :integer
  end
end
