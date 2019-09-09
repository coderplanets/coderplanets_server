defmodule GroupherServerWeb.Controller.OG do
  use GroupherServerWeb, :controller
  # alias Todos.Todo
  # plug(:action)

  def index(conn, _params) do
    # todos = Repo.all(Todo)
    json(conn, %{hello: "world"})
    # render(conn, %{hello: "world"})
    # text(conn, "BusiApi!")
  end
end
