defmodule MastaniServerWeb.Schema.Delivery.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware, as: M
  # alias MastaniServerWeb.Middleware

  object :delivery_mutations do
    field :mention_someone, :status do
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

    field :publish_system_notification, :status do
      arg(:source_id, non_null(:id))
      arg(:source_title, non_null(:string))
      arg(:source_type, non_null(:string))
      arg(:source_preview, :string)

      middleware(M.Authorize, :login)
      # TODO: use delivery passport system instead of cms's
      middleware(M.Passport, claim: "cms->system_notification.publish")

      resolve(&Resolvers.Delivery.publish_system_notification/3)
    end
  end
end
