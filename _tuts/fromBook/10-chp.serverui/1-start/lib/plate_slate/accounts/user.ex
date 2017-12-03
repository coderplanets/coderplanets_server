#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias PlateSlate.Accounts.User

  schema "users" do
    field :email, :string
    field :name, :string
    field :password, Comeonin.Ecto.Password
    field :role, :string

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :role])
    |> validate_required([:name, :email, :password, :role])
  end
end
