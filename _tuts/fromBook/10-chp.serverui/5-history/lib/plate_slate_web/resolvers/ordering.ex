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

  import Absinthe.Resolution.Helpers

  def order_history(item, args, _) do
    one_month_ago = Date.utc_today |> Date.add(-30)
    args = Map.update(args, :since, one_month_ago, fn date ->
      date || one_month_ago
    end)
    {:ok, %{item: item, args: args}}
  end

  def orders(%{item: item, args: args}, _, _) do
    batch({Ordering, :orders_by_item_name, args}, item.name, fn orders ->
      {:ok, Map.get(orders, item.name, [])}
    end)
  end

  def stat(stat) do
    fn %{item: item, args: args}, _, _ ->
      batch({Ordering, :orders_stats_by_name, args}, item.name, fn results ->
        {:ok, results[item.name][stat] || 0}
      end)
    end
  end

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
