defmodule MastaniServer.Test.AssertHelper do
  import Phoenix.ConnTest
  import Helper.Utils, only: [map_key_stringify: 1, get_config: 2]

  @endpoint MastaniServerWeb.Endpoint

  @page_size get_config(:pagi, :page_size)
  @inner_page_size get_config(:pagi, :inner_page_size)

  def non_exsit_id(), do: 15_982_398_614
  def inner_page_size(), do: @inner_page_size
  def page_size, do: @page_size

  def is_valid_kv?(obj, key, :list) when is_map(obj) do
    obj = map_key_stringify(obj)

    case Map.has_key?(obj, key) do
      true -> obj |> Map.get(key) |> is_list
      _ -> false
    end
  end

  def is_valid_kv?(obj, key, :int) when is_map(obj) do
    obj = map_key_stringify(obj)

    case Map.has_key?(obj, key) do
      true -> obj |> Map.get(key) |> is_integer
      _ -> false
    end
  end

  def is_valid_kv?(obj, key, :string) when is_map(obj) and is_binary(key) do
    obj = map_key_stringify(obj)

    case Map.has_key?(obj, key) do
      true -> String.length(Map.get(obj, key)) != 0
      _ -> false
    end
  end

  def is_valid_pagination?(obj) when is_map(obj) do
    is_valid_kv?(obj, "entries", :list) and is_valid_kv?(obj, "totalPages", :int) and
      is_valid_kv?(obj, "totalCount", :int) and is_valid_kv?(obj, "pageSize", :int) and
      is_valid_kv?(obj, "pageNumber", :int)
  end

  def is_valid_pagination?(obj, :raw) when is_map(obj) do
    is_valid_kv?(obj, "entries", :list) and is_valid_kv?(obj, "total_pages", :int) and
      is_valid_kv?(obj, "total_entries", :int) and is_valid_kv?(obj, "page_size", :int) and
      is_valid_kv?(obj, "page_number", :int)
  end

  def has_boolen_value?(obj, key) do
    obj |> Map.get(key) |> is_boolean
  end

  def mutation_result(conn, query, variables, key) do
    conn
    |> post("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> Map.get("data")
    |> Map.get(key)
  end

  def mutation_result(conn, query, variables, key, :debug) do
    IO.inspect(query, label: "query")
    IO.inspect(variables, label: "variables")

    conn
    |> post("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> IO.inspect(label: "mutation_result")
    |> Map.get("data")
    |> Map.get(key)
  end

  def mutation_get_error?(conn, query, variables) do
    conn
    |> post("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> Map.has_key?("errors")
  end

  def query_result(conn, query, variables, key) do
    conn
    |> get("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> Map.get("data")
    |> Map.get(key)
  end

  def query_result(conn, query, variables, key, :debug) do
    IO.inspect(query, label: "query")
    IO.inspect(variables, label: "variables")

    conn
    |> get("/graphiql", query: query, variables: variables)
    |> IO.inspect(label: "query_result")
    |> json_response(200)
    |> Map.get("data")
    |> Map.get(key)
  end

  def query_result(conn, query, key) do
    conn
    |> get("/graphiql", query: query, variables: %{})
    |> json_response(200)
    |> Map.get("data")
    |> Map.get(key)
  end

  def query_get_error?(conn, query, variables) do
    conn
    |> get("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> Map.has_key?("errors")
  end

  def query_get_error?(conn, query, variables, :debug) do
    IO.inspect(query, label: "query_get_error? query")
    IO.inspect(variables, label: "query_get_error? variables")

    conn
    |> get("/graphiql", query: query, variables: variables)
    |> IO.inspect(label: "query_get_error?")
    |> json_response(200)
    |> Map.has_key?("errors")
  end

  def firstn_and_last(values, 3) do
    [value_1 | [value_2 | [value_3 | _]]] = values
    value_x = values |> List.last()

    [value_1, value_2, value_3, value_x]
  end
end
