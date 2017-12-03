#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.AdminAuth do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    with id when not is_nil(id) <- get_session(conn, :employee_id),
    %{} = user <- PlateSlate.Accounts.lookup("employee", id) do
      conn
      |> Plug.Conn.assign(:current_user, user)
      |> Absinthe.Plug.put_options(context: %{current_user: user})
    else
      _ ->
        conn
        |> clear_session
        |> Phoenix.Controller.redirect(to: "/admin/session/new")
    end
  end
end
