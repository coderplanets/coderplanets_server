defmodule MastaniServer.AssertHelper do
  import Phoenix.ConnTest
  @endpoint MastaniServerWeb.Endpoint

  def is_valid_key?(obj, key, :list) when is_map(obj) do
    case Map.has_key?(obj, key) do
      true -> obj |> Map.get(key) |> is_list
      _ -> false
    end
  end

  def is_valid_key?(obj, key, :int) when is_map(obj) do
    case Map.has_key?(obj, key) do
      true -> obj |> Map.get(key) |> is_integer
      _ -> false
    end
  end

  def is_valid_key?(obj, key, :string) when is_map(obj) and is_binary(key) do
    case Map.has_key?(obj, key) do
      true -> String.length(Map.get(obj, key)) != 0
      _ -> false
    end
  end

  def is_valid_pagination?(obj) when is_map(obj) do
    obj |> is_valid_key?("entries", :list) and obj |> is_valid_key?("totalPages", :int) and
      obj |> is_valid_key?("totalCount", :int) and obj |> is_valid_key?("pageSize", :int) and
      obj |> is_valid_key?("pageNumber", :int)
  end

  def query_get_result_of(conn, query, variables, key) do
    conn
    |> get("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> Map.get("data")
    |> Map.get(key)
  end

  def query_get_result_of(conn, query, variables, key, :debug) do
    IO.inspect(query, label: "query")
    IO.inspect(variables, label: "variables")

    conn
    |> get("/graphiql", query: query, variables: variables)
    |> IO.inspect(label: "query_get_result_of")
    |> json_response(200)
    |> Map.get("data")
    |> Map.get(key)
  end

  def query_get_result_of(conn, query, key) do
    conn
    |> get("/graphiql", query: query, variables: %{})
    |> json_response(200)
    |> Map.get("data")
    |> Map.get(key)
  end

  def has_boolen_value?(obj, key) do
    obj |> Map.get(key) |> is_boolean
  end

  def query_get_error?(conn, query, variables) do
    conn
    |> get("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> Map.has_key?("errors")
  end
end
