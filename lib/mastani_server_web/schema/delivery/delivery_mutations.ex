defmodule MastaniServerWeb.Schema.Delivery.Mutations do
  @moduledoc """
  Delivery.Mutations
  """
  use Helper.GqlSchemaSuite

  object :delivery_mutations do
    field :mention_others, :status do
      arg(:user_ids, non_null(list_of(:ids)))

      arg(:source_id, non_null(:id))
      arg(:source_title, non_null(:string))
      arg(:source_type, non_null(:string))
      arg(:source_preview, non_null(:string))
      arg(:parent_id, :id)
      arg(:parent_type, :string)

      middleware(M.Authorize, :login)
      resolve(&R.Delivery.mention_others/3)
    end

    field :publish_system_notification, :status do
      arg(:source_id, non_null(:id))
      arg(:source_title, non_null(:string))
      arg(:source_type, non_null(:string))
      arg(:source_preview, :string)

      middleware(M.Authorize, :login)
      # TODO: use delivery passport system instead of cms's
      middleware(M.Passport, claim: "cms->system_notification.publish")

      resolve(&R.Delivery.publish_system_notification/3)
    end
  end
end
