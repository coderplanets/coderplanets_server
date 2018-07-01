defmodule MastaniServerWeb.Schema.Delivery.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware, as: M
  # alias MastaniServerWeb.Middleware

  object :delivery_mutations do
    field :mention_someone, :mention do
      arg(:user_id, non_null(:id))

      arg(:source_id, non_null(:id))
      arg(:source_title, non_null(:string))
      arg(:source_type, non_null(:string))
      arg(:source_preview, non_null(:string))
      arg(:parent_id, :id)
      arg(:parent_type, :string)

      middleware(M.Authorize, :login)

      resolve(&Resolvers.Delivery.mention_someone/3)
    end
  end
end
