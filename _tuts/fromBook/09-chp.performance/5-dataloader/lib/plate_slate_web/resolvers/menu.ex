#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Resolvers.Menu do
  alias PlateSlate.Menu

  import Absinthe.Resolution.Helpers, only: [on_load: 2]

  def menu_items(_, args, _) do
    {:ok, Menu.list_items(args)}
  end

  def search(_, %{matching: term}, _) do
    {:ok, Menu.search(term)}
  end

  def items_for_category(category, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(Menu, {:items, args}, category)
    |> on_load(fn loader ->
      items = Dataloader.get(loader, Menu, {:items, args}, category)
      {:ok, items}
    end)
  end

  def category_for_item(menu_item, _, %{context: %{loader: loader}}) do
    loader |> IO.inspect
    loader
    |> Dataloader.load(Menu, :category, menu_item)
    |> on_load(fn loader ->
      category = Dataloader.get(loader, Menu, :category, menu_item)
      {:ok, category}
    end)
  end

  def create_item(_, %{input: params}, _) do
    with {:ok, item} <- Menu.create_item(params) do
      {:ok, %{menu_item: item}}
    end
  end

end
