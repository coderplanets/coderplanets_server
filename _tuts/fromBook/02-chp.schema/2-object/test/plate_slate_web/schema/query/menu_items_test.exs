#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Query.MenuItemsTest do
  use PlateSlateWeb.ConnCase, async: true

  setup do
    Code.load_file("priv/repo/seeds.exs") 
  end

  @query """
  {
    menuItems {
      name
    }
  }
  """
  test "menuItems field returns menu items" do
    conn = build_conn() 
    conn = get conn, "/api", query: @query
    assert json_response(conn, 200) == %{ 
      "data" => %{
        "menuItems" => [
          %{"name" => "Rueben"},
          %{"name" => "Croque Monsieur"},
          %{"name" => "Muffuletta"},
          # Rest of items
          %{"name" => "Bánh mì"},
          %{"name" => "Vada Pav"},
          %{"name" => "French Fries"},
          %{"name" => "Papadum"},
          %{"name" => "Pasta Salad"},
          %{"name" => "Water"},
          %{"name" => "Soft Drink"},
          %{"name" => "Lemonade"},
          %{"name" => "Masala Chai"},
          %{"name" => "Vanilla Milkshake"},
          %{"name" => "Chocolate Milkshake"},
        ]
      }
    }
  end

end
