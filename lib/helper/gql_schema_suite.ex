defmodule Helper.GqlSchemaSuite do
  @moduledoc """
  helper for reduce boilerplate import/use/alias in absinthe schema
  """

  defmacro __using__(_opts) do
    quote do
      use Absinthe.Schema.Notation
      use Absinthe.Ecto, repo: MastaniServerWeb.Repo

      alias MastaniServerWeb.Resolvers, as: R
      alias MastaniServerWeb.Middleware, as: M
    end
  end
end
