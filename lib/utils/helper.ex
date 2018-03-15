defmodule MastaniServer.Utils.Helper do
  alias MastaniServer.Repo
  import Ecto.Query, warn: false

  @doc """
  return General {:ok, ..} or {:error, ..} return value
  """

  def find(queryable, id, preload: preload) do
    queryable
    |> preload(^preload)
    |> Repo.get(id)
    |> done()
  end

  def find(queryable, id) do
    queryable
    |> Repo.get(id)
    |> done()
  end

  def find_by(queryable, clauses) do
    queryable
    |> Repo.get_by(clauses)
    |> case do
      nil ->
        sort_name = queryable |> to_string |> String.split(".") |> List.last()
        detail = clauses |> Enum.into(%{}) |> Map.values() |> to_string
        {:error, "#{sort_name}(#{detail}) not found"}

      result ->
        {:ok, result}
    end
  end

  def done(nil), do: {:error, "record not found."}
  def done(result), do: {:ok, result}

  def done(nil, :boolean), do: {:ok, false}
  def done(result, :boolean), do: {:ok, true}

  # def done(nil, :maybe), do: {:error, "record not found."}
  # def done(result, :maybe), do: {:ok, result}

  # def done(nil, :maybe, message), do: {:error, message}
  # def done(result, :maybe, _), do: {:ok, result}

  def operation_deny(type) do
    case type do
      :owner_required -> {:error, "Access denied: need owner to do this"}
      :root -> {:error, "need root to do this"}
    end
  end

  def paginater(queryable, page: page, size: size) do
    queryable |> Repo.paginate(page: page, page_size: size) |> done()
  end
end
