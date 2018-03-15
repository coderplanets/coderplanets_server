defmodule MastaniServer.Utils.Helper do
  alias MastaniServer.Repo
  import Ecto.Query, warn: false

  def paginater(queryable, page: page, size: size) do
    queryable |> Repo.paginate(page: page, page_size: size) |> done()
  end

  @doc """
  wrap Repo.get with result/errer format handle
  """
  def find(queryable, id, preload: preload) do
    queryable
    |> preload(^preload)
    |> Repo.get(id)
    |> done(queryable, id)
  end

  def find(queryable, id) do
    queryable
    |> Repo.get(id)
    |> done(queryable, id)
  end

  def find_by(queryable, clauses) do
    queryable
    |> Repo.get_by(clauses)
    |> case do
      nil ->
        {:error, not_found_formater(queryable, clauses)}

      result ->
        {:ok, result}
    end
  end

  @doc """
  return General {:ok, ..} or {:error, ..} return value
  """

  def done(nil, :boolean), do: {:ok, false}
  def done(result, :boolean), do: {:ok, true}
  def done(nil, err_msg), do: {:error, err_msg}

  def done(nil, queryable, id), do: {:error, not_found_formater(queryable, id)}
  def done(result, _, _), do: {:ok, result}

  def done(nil), do: {:error, "record not found."}
  def done(result), do: {:ok, result}

  def operation_deny(type) do
    case type do
      :owner_required -> {:error, "Access denied: need owner to do this"}
      :root -> {:error, "Access denied: need root to do this"}
    end
  end

  defp not_found_formater(queryable, id) when is_integer(id) do
    modal_sortname = queryable |> to_string |> String.split(".") |> List.last()
    "#{modal_sortname}(#{id}) not found"
  end

  defp not_found_formater(queryable, clauses) do
    modal_sortname = queryable |> to_string |> String.split(".") |> List.last()

    detail =
      clauses
      |> Enum.into(%{})
      |> Map.values()
      |> List.first()
      |> to_string

    "#{modal_sortname}(#{detail}) not found"
  end
end
