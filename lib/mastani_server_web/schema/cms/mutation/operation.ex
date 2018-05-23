defmodule MastaniServerWeb.Schema.CMS.Mutation.Operation do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.{Resolvers}
  alias MastaniServerWeb.Middleware, as: M

  object :cms_mutation_operation do
    @desc "set category to a community"
    field :set_category, :community do
      arg(:community_id, non_null(:id))
      arg(:category_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->category.set")

      resolve(&Resolvers.CMS.set_category/3)
    end

    @desc "unset category to a community"
    field :unset_category, :community do
      arg(:community_id, non_null(:id))
      arg(:category_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->category.unset")

      resolve(&Resolvers.CMS.unset_category/3)
    end

    @desc "link a exist thread to a exist community"
    field :add_thread_to_community, :community do
      arg(:community_id, non_null(:id))
      arg(:thread_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->thread.add")

      resolve(&Resolvers.CMS.add_thread_to_community/3)
    end

    # field :delete_thread_from_community, :community do
    # arg(:community_id, non_null(:id))
    # arg(:thread_id, non_null(:id))

    # middleware(M.Authorize, :login)
    # middleware(M.PassportLoader, source: :community)
    # middleware(M.Passport, claim: "cms->c?->thread.delete")

    # resolve(&Resolvers.CMS.add_thread_to_community/3)
    # end

    # @desc "set passport details for a user TODO: unset"
    # field :set_cms_passport, :user do
    # args(:userId, non_null(:id))
    # args(:detail, non_null(:string))

    # middleware(M.Authorize, :login)
    # middleware(M.Passport, claim: "cms->community.set_editor")

    # resolve(&Resolvers.CMS.stamp_passport/3)
    # end

    @desc "subscribe a community so it can appear in sidebar"
    field :subscribe_community, :community do
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.subscribe_community/3)
    end

    @desc "unsubscribe a community"
    field :unsubscribe_community, :community do
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.unsubscribe_community/3)
    end

    @desc "set a tag within community"
    field :set_tag, :tag do
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->p?.tag.set")

      resolve(&Resolvers.CMS.set_tag/3)
    end

    @desc "unset a tag within community"
    field :unset_tag, :tag do
      # part id
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->p?.tag.set")

      resolve(&Resolvers.CMS.unset_tag/3)
    end

    # TODO: use community loader
    field :set_community, :community do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->p?.community.set")
      resolve(&Resolvers.CMS.set_community/3)
    end

    field :unset_community, :community do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->p?.community.set")
      resolve(&Resolvers.CMS.unset_community/3)
    end

    field :reaction, :article do
      arg(:id, non_null(:id))
      arg(:part, non_null(:cms_part))
      arg(:action, non_null(:cms_action))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.reaction/3)
    end

    field :undo_reaction, :article do
      arg(:id, non_null(:id))
      arg(:part, non_null(:cms_part))
      arg(:action, non_null(:cms_action))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.undo_reaction/3)
    end
  end
end
