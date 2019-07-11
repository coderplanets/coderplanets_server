defmodule Helper.Later do
  @moduledoc """
  background jobs support, currently using https://github.com/samphilipd/rihanna
  """

  @doc """
  ## Example
  iex> Later.exec({__MODULE__, :get_contributes_then_cache, [%Community{id: id}]})
  {:ok, _}
  """
  def exec({mod, func, args}) do
    Rihanna.enqueue({mod, func, args})
  end
end
