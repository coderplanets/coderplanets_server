#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Subscription.UpdateOrderTest do
  use PlateSlateWeb.SubscriptionCase

  @subscription """
  subscription ($id: ID! ){
    updateOrder(id: $id) { state }
  }
  """
  @mutation """
  mutation ($id: ID!) {
    readyOrder(id: $id) { errors { message } }
  }
  """
  test "subscribe to order updates", %{socket: socket} do
    rueben = menu_item("Rueben")

    {:ok, order1} = PlateSlate.Ordering.create_order(%{
      customer_number: 123, items: [%{menu_item_id: rueben.id, quantity: 2}]
    })
    {:ok, order2} = PlateSlate.Ordering.create_order(%{
      customer_number: 124, items: [%{menu_item_id: rueben.id, quantity: 1}]
    })

    ref = push_doc(socket, @subscription, variables: %{"id" => order1.id})
    assert_reply ref, :ok, %{subscriptionId: _subscription_ref1}

    ref = push_doc(socket, @subscription, variables: %{"id" => order2.id})
    assert_reply ref, :ok, %{subscriptionId: subscription_ref2}

    ref = push_doc(socket, @mutation, variables: %{"id" => order2.id})
    assert_reply ref, :ok, reply

    refute reply[:errors]
    refute reply[:data]["readyOrder"]["errors"]

    assert_push "subscription:data", push
    expected = %{
      result: %{data: %{"updateOrder" => %{"state" => "ready"}}},
      subscriptionId: subscription_ref2
    }
    assert expected == push
  end
end
