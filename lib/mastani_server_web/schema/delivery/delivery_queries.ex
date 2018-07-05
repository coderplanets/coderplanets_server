defmodule MastaniServerWeb.Schema.Delivery.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo
  # import Absinthe.Resolution.Helpers
  alias MastaniServerWeb.{Resolvers}

  object :delivery_queries do
    @desc "get mention list?"
    field :xxxx_todo, :boolean do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Delivery.mention_someone/3)
    end
  end
end
