#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Middleware.Debug do

  @behaviour Absinthe.Middleware

  def call(resolution, :start) do
    path = resolution |> Absinthe.Resolution.path |> Enum.join(".")
    IO.puts """
    ======================
    starting: #{path}
    with source: #{inspect resolution.source}\
    """
    %{resolution |
      middleware: resolution.middleware ++ [{__MODULE__, {:finish, path}}]
    }
  end
  def call(resolution, {:finish, path}) do
    IO.puts """
    completed: #{path}
    value: #{inspect resolution.value}
    ======================\
    """
    resolution
  end
end
