defmodule Helper.Later do
  @moduledoc """
  background jobs support, currently using https://github.com/samphilipd/rihanna
  """

  @doc """
  ## Example
  iex> Later.run({__MODULE__, :get_contributes_then_cache, [%Community{id: id}]})
  {:ok, _}
  """
  def run({mod, func, args}) do
    Rihanna.enqueue({mod, func, args})
    # weather enqueue success or not, just return {:ok, :pass}, or Multi.Job will be rollback
    {:ok, :pass}
  end
end
