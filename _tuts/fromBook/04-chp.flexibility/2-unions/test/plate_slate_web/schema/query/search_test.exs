#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Query.SearchTest do
  use PlateSlateWeb.ConnCase, async: true

  setup do
    Code.load_file("priv/repo/seeds.exs")
  end

  @query """
  query Search($term: String!) {
    search(matching: $term) {
      ... on MenuItem { name }
      ... on Category { name }
      __typename
    }
  }
  """
  @variables %{term: "e"}
  test "search returns a list of menu items and categories" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)
    assert %{"data" => %{"search" => results}} = json_response(response, 200)
    assert length(results) > 0
    assert Enum.find(results, &(&1["__typename"] == "Category"))
    assert Enum.find(results, &(&1["__typename"] == "MenuItem"))
  end
end
