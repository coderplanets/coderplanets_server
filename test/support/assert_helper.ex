defmodule GroupherServer.Test.AssertHelper do
  @moduledoc """
  This module defines some helper function used by
  tests that require check from graphql response

  NOTE: we use POST in query_get, see https://github.com/coderplanets/coderplanets_server/issues/259
  """

  import Helper.ErrorCode, only: [ecode: 1]
  import Phoenix.ConnTest
  import Helper.Utils, only: [map_key_stringify: 1, get_config: 2]

  @endpoint GroupherServerWeb.Endpoint

  @inner_page_size get_config(:general, :inner_page_size)

  @doc """
  used for non exsit id
  """
  def non_exsit_id, do: 15_982_398_614
  def non_exsit_login, do: "15_982_398_614"
  # def page_size, do: @page_size

  def is_error?(reason, code) when is_list(reason) and is_atom(code) do
    reason |> Keyword.get(:code) == ecode(code)
  end

  def assert_v(:inner_page_size), do: @inner_page_size

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

  def is_valid_pagination?(obj, :empty) when is_map(obj) do
    case is_valid_pagination?(obj) do
      false ->
        false

      true ->
        obj["entries"] |> Enum.empty?() and obj["totalCount"] == 0 and obj["pageNumber"] == 1 and
          obj["totalPages"] == 1
    end
  end

  def is_valid_pagination?(obj, :raw) when is_map(obj) do
    is_valid_kv?(obj, "entries", :list) and is_valid_kv?(obj, "total_pages", :int) and
      is_valid_kv?(obj, "total_count", :int) and is_valid_kv?(obj, "page_size", :int) and
      is_valid_kv?(obj, "page_number", :int)
  end

  def is_valid_pagination?(obj, :raw, :empty) when is_map(obj) do
    case is_valid_pagination?(obj, :raw) do
      false ->
        false

      true ->
        obj.entries |> Enum.empty?() and obj.total_count == 0 and obj.page_number == 1 and
          obj.total_pages == 1
    end
  end

  def has_boolen_value?(obj, key) do
    obj |> Map.get(key) |> is_boolean
  end

  @doc """
  simulate the Graphiql murate operation
  """
  def mutation_result(conn, query, variables, key, flag \\ false) do
    conn
    |> post("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> log_debug_info(flag)
    |> Map.get("data")
    |> Map.get(key)
  end

  @doc """
  check if Graphiql murate get error
  """
  def mutation_get_error?(conn, query, variables, flag \\ false)

  @doc """
  Graphiql murate error with code equal check
  """
  def mutation_get_error?(conn, query, variables, code) when is_integer(code) do
    resp =
      conn
      |> post("/graphiql", query: query, variables: variables)
      |> json_response(200)

    # IO.inspect(resp, label: "debug")

    case resp |> Map.has_key?("errors") do
      true ->
        code == resp["errors"] |> List.first() |> Map.get("code")

      false ->
        false
    end
  end

  def mutation_get_error?(conn, query, variables, flag) do
    conn
    |> post("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> log_debug_info(flag)
    |> Map.has_key?("errors")
  end

  def query_result(conn, query, variables, key, flag \\ false) do
    conn
    |> post("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> log_debug_info(flag)
    |> Map.get("data")
    |> Map.get(key)
  end

  def query_result(conn, query, key) do
    conn
    |> post("/graphiql", query: query, variables: %{})
    |> json_response(200)
    |> Map.get("data")
    |> Map.get(key)
  end

  def query_get_error?(conn, query, variables) do
    conn
    |> post("/graphiql", query: query, variables: variables)
    |> json_response(200)
    |> Map.has_key?("errors")
  end

  @doc """
  check if Graphiql murate get error
  """
  def query_get_error?(conn, query, variables, code) when is_integer(code) do
    resp =
      conn
      |> post("/graphiql", query: query, variables: variables)
      |> json_response(200)

    case resp |> Map.has_key?("errors") do
      true ->
        code == resp["errors"] |> List.first() |> Map.get("code")

      false ->
        false
    end
  end

  def firstn_and_last(values, 3) do
    [value_1 | [value_2 | [value_3 | _]]] = values
    value_x = values |> List.last()

    [value_1, value_2, value_3, value_x]
  end

  # log response info if need
  # usage:
  # user_conn |> mutation_result(@query, variables, "createRepo")
  # user_conn |> mutation_result(@query, variables, "createRepo", :debug)
  defp log_debug_info(res, :debug), do: IO.inspect(res, label: "debug")
  defp log_debug_info(res, _), do: res

  @doc "check id is exsit in list of Map<id: xxx> structure"
  @spec exist_in?(Map.t(), [Map.t()]) :: boolean
  def exist_in?(%{id: id}, list) when is_list(list) do
    list
    |> Enum.any?(fn item ->
      to_string(id) == to_string(Map.get(item, :id, Map.get(item, "id")))
    end)
  end

  # def user_exist_in?(%{id: id}, list) when is_list(list) do
  #   list |> Enum.any?(&(&1["id"] == to_string(id)))
  # end

  # for embed user situation
  def user_exist_in?(%{login: login}, list) when is_list(list) do
    # list |> Enum.any?(&(&1.login == login or &1["login"] == login))
    list
    |> Enum.any?(fn u ->
      login == Map.get(u, :login, Map.get(u, "login"))
    end)
  end
end
