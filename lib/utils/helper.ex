defmodule MastaniServer.Utils.Helper do
  alias MastaniServer.Repo
  import Ecto.Query, warn: false

  @doc """
  return General {:ok, ..} or {:error, ..} return value
  """

  def find(queryable, id, preload: preload) do
    queryable
    |> where([c], c.id == ^id)
    |> preload(^preload)
    |> Repo.one()
    |> one_resp()
  end

  def find(queryable, id) do
    queryable
    |> where([c], c.id == ^id)
    |> Repo.one()
    |> one_resp()
  end

  def one_resp(message) do
    case message do
      nil ->
        {:error, "record not found."}

      result ->
        {:ok, result}
    end
  end

  def access_deny(type) do
    case type do
      :login -> {:error, "Access denied: need login to do this"}
      :owner_required -> {:error, "Access denied: need owner to do this"}
      :root -> {:error, "need root to do this"}
    end
  end

  def paginater(queryable, page: page, size: size) do
    result = queryable |> Repo.paginate(page: page, page_size: size)
    {:ok, result}
  end
end
