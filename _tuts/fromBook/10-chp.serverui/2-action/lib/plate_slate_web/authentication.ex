#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Authentication do
  @user_salt "user salt"

  def sign(data) do
    Phoenix.Token.sign(PlateSlateWeb.Endpoint, @user_salt, data)
  end

  def verify(token) do
    Phoenix.Token.verify(PlateSlateWeb.Endpoint, @user_salt, token, [
      max_age: 365 * 24 * 3600
    ])
  end

end
