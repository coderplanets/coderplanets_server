#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Middleware.Loader do
  @behaviour Absinthe.Middleware
  @behaviour Absinthe.Plugin

  def before_resolution(%{context: context} = exec) do
    context = with %{loader: loader} <- context do
      %{context | loader: DataLoader.run(loader)}
    end

    %{exec | context: context}
  end

  def call(%{state: :unresolved} = resolution, {:load, loader, callback}) do
    %{resolution |
      context: Map.put(resolution.context, :loader, loader),
      state: :suspended,
      middleware: [{__MODULE__, {:get, callback}} | resolution.middleware]
    }
  end
  def call(resolution, {:get, callback}) do
    value = callback.(resolution.context.loader)
    Absinthe.Resolution.put_result(resolution, value)
  end

  def after_resolution(exec) do
    exec
  end

  def pipeline(pipeline, exec) do
    with %{loader: loader} <- exec.context,
    true <- DataLoader.pending_batches?(loader) do
      [Absinthe.Phase.Document.Execution.Resolution | pipeline]
    else
      _ -> pipeline
    end
  end


end
