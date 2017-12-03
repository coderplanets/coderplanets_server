#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias PlateSlate.Repo
  alias Comeonin.Ecto.Password

  alias PlateSlate.Accounts.User

  def authenticate(role, email, password) do
    user = Repo.get_by(User, role: role, email: email)

    with %{password: digest} <- user,
    true <- Password.valid?(password, digest) do
      {:ok, user}
    else
      _ -> :error
    end
  end
end
