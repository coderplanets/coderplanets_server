#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Mutation.CreateMenuTest do
  use PlateSlateWeb.ConnCase, async: true

  alias PlateSlate.{Repo, Menu}
  import Ecto.Query

  setup do
    Code.load_file("priv/repo/seeds.exs")

    category_id =
      from(t in Menu.Category, where: t.name == "Sandwiches")
      |> Repo.one!
      |> Map.fetch!(:id)
      |> to_string

    {:ok, category_id: category_id}
  end

  @query """
  mutation ($menuItem: MenuItemInput!) {
    createMenuItem(input: $menuItem) {
      errors { key message }
      menuItem {
        name
        description
        price
      }
    }
  }
  """
  test "createMenuItem field creates a menuItem", %{category_id: category_id} do
    menu_item = %{
      "name" => "French Dip",
      "description" => "Roast beef, caramelized onions, horseradish, ...",
      "price" =>  "5.75",
      "categoryId" => category_id,
    }
    user = Factory.create_user("employee")
    conn = build_conn() |> auth_user(user)
    conn = post conn, "/api", query: @query, variables: %{"menuItem" => menu_item}
    assert json_response(conn, 200) == %{
      "data" => %{
        "createMenuItem" => %{
          "errors" => nil,
          "menuItem" => %{
            "name" => menu_item["name"],
            "description" => menu_item["description"],
            "price" => menu_item["price"]
          }
        }
      }
    }
  end

  defp auth_user(conn, user) do
    token = PlateSlateWeb.Authentication.sign(%{role: user.role, id: user.id})
    put_req_header(conn, "authorization", "Bearer #{token}")
  end

  test "creating a menu item with an existing name fails",
  %{category_id: category_id} do
    menu_item = %{
      "name" => "Rueben",
      "description" => "Roast beef, caramelized onions, horseradish, ...",
      "price" =>  "5.75",
      "categoryId" => category_id,
    }
    user = Factory.create_user("employee")
    conn = build_conn() |> auth_user(user)
    conn = post conn, "/api", query: @query, variables: %{"menuItem" => menu_item}
    assert json_response(conn, 200) == %{
      "data" => %{
        "createMenuItem" => %{
          "errors" => [
            %{"key" => "name", "message" => "has already been taken"}
          ],
          "menuItem" => nil
        }
      }
    }
  end

  test "must be authorized as an employee to do menu item creation",
  %{category_id: category_id} do
    menu_item = %{
      "name" => "Rueben",
      "description" => "Roast beef, caramelized onions, horseradish, ...",
      "price" =>  "5.75",
      "categoryId" => category_id,
    }
    user = Factory.create_user("customer")
    conn = build_conn() |> auth_user(user)
    conn = post conn, "/api", query: @query, variables: %{"menuItem" => menu_item}
    assert json_response(conn, 200) == %{
      "data" => %{"createMenuItem" => nil},
      "errors" => [%{
        "locations" => [%{"column" => 0, "line" => 2}],
        "message" => "unauthorized",
        "path" => ["createMenuItem"]
      }]
    }
  end

end
