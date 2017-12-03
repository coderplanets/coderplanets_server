#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.ItemController do
  use PlateSlateWeb, :controller
  use Absinthe.Phoenix.Controller,
    schema: PlateSlateWeb.Schema,
    action: [mode: :internal]
  # Rest of controller


  @graphql """
  query {
    menu_items @put {
      category
      order_history {
        quantity
      }
    }
  }
  """
  def index(conn, result) do
    render(conn, "index.html", items: result.data.menu_items)
  end

  @graphql """
  query ($id: ID!, $since: Date) {
    menu_item(id: $id) @put {
      order_history(since: $since) {
        quantity
        gross
        orders
      }
    }
  }
  """
  def show(conn, %{data: %{menu_item: nil}}) do
    conn
    |> put_flash(:info, "Menu item not found")
    |> redirect(to: "/admin/items")
  end
  def show(conn, %{data: %{menu_item: item}}) do
    render(conn, "show.html", item: item)
  end
end
