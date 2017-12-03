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
    assert json_response(conn, 200) == %{"data" => %{"menuItems" => [
      %{"name" => "Bánh mì"},
      %{"name" => "Chocolate Milkshake"},
      %{"name" => "Croque Monsieur"},
      %{"name" => "French Fries"},
      %{"name" => "Lemonade"},
      %{"name" => "Masala Chai"},
      %{"name" => "Muffuletta"},
      %{"name" => "Papadum"},
      %{"name" => "Pasta Salad"},
      %{"name" => "Rueben"},
      %{"name" => "Soft Drink"},
      %{"name" => "Vada Pav"},
      %{"name" => "Vanilla Milkshake"},
      %{"name" => "Water"}
    ]}}
  end

  @query """
  {
    menuItems(matching: "rue") {
      name
    }
  }
  """
  test "menuItems field returns menu items filtered by name" do
    response = get(build_conn(), "/api", query: @query)
    assert json_response(response, 200) == %{
      "data" => %{
        "menuItems" => [
          %{"name" => "Rueben"},
        ]
      }
    }
  end

  @query """
  {
    menuItems(matching: 123) {
      name
    }
  }
  """
  test "menuItems field returns errors when using a bad value" do
    response = get(build_conn(), "/api", query: @query)
    assert %{"errors" => [
      %{"message" => message}
    ]} = json_response(response, 400)
    assert message == "Argument \"matching\" has invalid value 123."
  end

  @query """
  query ($term: String) {
    menuItems(matching: $term) {
      name
    }
  }
  """
  @variables %{"term" => "rue"}
  test "menuItems field returns menuItems filtered by name when using a variable" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)
    assert json_response(response, 200) == %{
      "data" => %{
        "menuItems" => [
          %{"name" => "Rueben"},
        ]
      }
    }
  end

  @query """
  {
    menuItems(order: DESC) {
      name
    }
  }
  """
  test "menuItems field returns menuItems descending when asked using literals" do
    response = get(build_conn(), "/api", query: @query)
    assert %{
      "data" => %{"menuItems" => [%{"name" => "Water"} | _]}
    } = json_response(response, 200)
  end

  @query """
  {
    menuItems(order: ASC) {
      name
    }
  }
  """
  test "menuItems field returns menuItems ascending when asked using literals" do
    response = get(build_conn(), "/api", query: @query)
    assert %{"data" => %{"menuItems" => [%{"name" => "Bánh mì"} | _]}} = json_response(response, 200)
  end

  @query """
  query ($order: SortOrder!) {
    menuItems(order: $order) {
      name
    }
  }
  """
  @variables %{"order" => "DESC"}
  test "menuItems field returns menuItems descending when asked using variables" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)
    assert %{
      "data" => %{"menuItems" => [%{"name" => "Water"} | _]}
    } = json_response(response, 200)
  end

  @variables %{"order" => "ASC"}
  test "menuItems field returns menuItems ascending when asked using variables" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)
    assert %{"data" => %{"menuItems" => [%{"name" => "Bánh mì"} | _]}} = json_response(response, 200)
  end

end
