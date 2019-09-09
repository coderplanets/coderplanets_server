defmodule GroupherServerWeb.Test.Controller.OG do
  @moduledoc """
  test open-graph fether
  """
  use GroupherServer.TestTools

  @tag :wip2
  test "basic should work" do
    conn = build_conn()

    res = get(conn, "/api/og-info")
    # res = conn(:get, "/api/og-info")
    # |> put_private(:plug_skip_csrf_protection, true)
    # |> GroupherServerWeb.Endpoint.call([])

    IO.inspect(json_response(res, 200), label: "res")
    # IO.inspect(text_response(res, 200), label: "res")
    # conn = get conn, todo_path(conn, :index)

    # IO.inspect json_response(conn, 200), label: "lulu"

    # assert json_response(conn, 200) == %{
    #   "todos" => [%{
    #     "title" => todo.title,
    #     "description" => todo.description,
    #     "inserted_at" => Ecto.DateTime.to_iso8601(todo.inserted_at),
    #     "updated_at" => Ecto.DateTime.to_iso8601(todo.updated_at)
    #   }]
    # }
  end
end
