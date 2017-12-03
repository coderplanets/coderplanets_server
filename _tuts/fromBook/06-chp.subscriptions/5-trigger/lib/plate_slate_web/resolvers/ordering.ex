#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Resolvers.Ordering do
  alias PlateSlate.Ordering

  def ready_order(_, %{id: id}, _) do
    order = Ordering.get_order!(id)
    with {:ok, order} <- Ordering.update_order(order, %{state: "ready"}) do
      {:ok, %{order: order}}
    else
      {:error, changeset} ->
        {:ok, %{errors: transform_errors(changeset)}}
    end
  end

  def complete_order(_, %{id: id}, _) do
    order = Ordering.get_order!(id)

    with {:ok, order} <- Ordering.update_order(order, %{state: "complete"}) do
      {:ok, %{order: order}}
    else
      {:error, changeset} ->
        {:ok, %{errors: transform_errors(changeset)}}
    end
  end

  def place_order(_, %{input: place_order_input}, _) do
    case Ordering.create_order(place_order_input) do
      {:ok, order} ->
        Absinthe.Subscription.publish(PlateSlateWeb.Endpoint, order,
          new_order: "*"
        )
        {:ok, %{order: order}}
      {:error, changeset} ->
        {:ok, %{errors: transform_errors(changeset)}}
    end
  end

  defp transform_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&format_error/1)
    |> Enum.map(fn
      {key, value} ->
        %{key: key, message: value}
    end)
  end

  @spec format_error(Ecto.Changeset.error) :: String.t
  defp format_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
