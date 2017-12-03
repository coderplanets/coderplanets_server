#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Resolvers.Ordering do
  alias PlateSlate.Ordering

  def ready_order(_, %{id: id}, _) do
    order = Ordering.get_order!(id)
    with {:ok, order} <- Ordering.update_order(order, %{state: "ready"}) do
      {:ok, %{order: order}}
    end
  end

  def complete_order(_, %{id: id}, _) do
    order = Ordering.get_order!(id)

    with {:ok, order} <- Ordering.update_order(order, %{state: "complete"}) do
      {:ok, %{order: order}}
    end
  end

  def place_order(_, %{input: place_order_input}, _) do
    with {:ok, order} <- Ordering.create_order(place_order_input) do
      Absinthe.Subscription.publish(PlateSlateWeb.Endpoint, order,
        new_order: "*"
      )
      {:ok, %{order: order}}
    end
  end
end
