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
    schema: PlateSlateWeb.Schema

  @graphql """
  query Index @action(mode: INTERNAL) {
    menu_items
  }
  """
  def index(conn, result) do
    result |> IO.inspect
    render(conn, "index.html", items: result.data.menu_items)
  end
end
