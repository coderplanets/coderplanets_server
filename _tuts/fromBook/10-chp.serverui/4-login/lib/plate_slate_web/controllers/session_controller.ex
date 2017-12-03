#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.SessionController do
  use PlateSlateWeb, :controller
  use Absinthe.Phoenix.Controller,
    schema: PlateSlateWeb.Schema,
    action: [mode: :internal]

  def new(conn, _) do
    render(conn, "new.html")
  end

  @graphql """
  mutation ($email: String!, $password: String!) {
    login_employee(email: $email, password: $password)
  }
  """
  def create(conn, %{data: %{login_employee: result}}) do
    case result do
      %{employee: employee} ->
        conn
        |> put_session(:employee_id, employee.id)
        |> put_flash(:info, "Login successful")
        |> redirect(to: "/admin/items")
      _ ->
        conn
        |> put_flash(:info, "Wrong email or password")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> clear_session
    |> redirect(to: "/admin/session/new")
  end
end
