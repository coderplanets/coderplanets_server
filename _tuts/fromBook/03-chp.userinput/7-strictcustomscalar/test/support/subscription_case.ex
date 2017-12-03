#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.SubscriptionCase do
  @moduledoc """
  This module defines the test case to be used by
  subscription tests
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      use PlateSlateWeb.ChannelCase
      use Absinthe.Phoenix.SubscriptionTest,
        schema: PlateSlateWeb.Schema

      setup do
        Code.load_file("priv/repo/seeds.exs")

        {:ok, socket} = Phoenix.ChannelTest.connect(PlateSlateWeb.UserSocket, %{})
        {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

        {:ok, socket: socket}
      end

      import unquote(__MODULE__), only: [menu_item: 1]
    end
  end

  # handy function for grabbing a fixture
  def menu_item(name) do
    PlateSlate.Repo.get_by!(PlateSlate.Menu.Item, name: name)
  end
end
