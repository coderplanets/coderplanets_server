defmodule GroupherServerWeb.Middleware.ForceLoader do
  @moduledoc """
  # this is a tmp solution for load related-users like situations
  # it turn dataloader into nomal N+1 resolver
  # NOTE: it should be replaced using "Select-Top-N-By-Group" solution
  """
  @behaviour Absinthe.Middleware

  def call(%{source: %{id: id}} = resolution, _) do
    arguments = resolution.arguments |> Map.merge(%{what_ever: id})

    %{resolution | arguments: arguments}
    # resolution
  end

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(resolution, _) do
    resolution
  end
end
