defmodule MastaniServerWeb.Schema.CMS.Mutation.Operation do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.{Resolvers}
  alias MastaniServerWeb.Middleware, as: M

  object :cms_opertion_mutations do
    # field :undo_pin_post, :post do
    field :pin_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.pin")
      resolve(&Resolvers.CMS.pin_post/3)
    end

    field :undo_pin_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.undo_pin")
      resolve(&Resolvers.CMS.undo_pin_post/3)
    end

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

    @desc "bind a thread to a exist community"
    field :set_thread, :community do
      arg(:community_id, non_null(:id))
      arg(:thread_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->thread.set")

      resolve(&Resolvers.CMS.set_thread/3)
    end

    @desc "remove a thread from a exist community, thread content is not delete"
    field :unset_thread, :community do
      arg(:community_id, non_null(:id))
      arg(:thread_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->thread.unset")

      resolve(&Resolvers.CMS.unset_thread/3)
    end

    @desc "stamp rules on user's passport"
    field :stamp_cms_passport, :idlike do
      arg(:user_id, non_null(:id))
      arg(:rules, non_null(:json))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.stamp_passport")

      resolve(&Resolvers.CMS.stamp_passport/3)
    end

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
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.tag.set")

      resolve(&Resolvers.CMS.set_tag/3)
    end

    @desc "unset a tag within community"
    field :unset_tag, :tag do
      # thread id
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.tag.unset")

      resolve(&Resolvers.CMS.unset_tag/3)
    end

    # TODO: use community loader
    field :set_community, :community do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->t?.community.set")
      resolve(&Resolvers.CMS.set_community/3)
    end

    # TODO: can't not unset the oldest community
    field :unset_community, :community do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->t?.community.unset")
      resolve(&Resolvers.CMS.unset_community/3)
    end

    field :reaction, :article do
      arg(:id, non_null(:id))
      arg(:thread, non_null(:cms_thread))
      arg(:action, non_null(:cms_action))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.reaction/3)
    end

    field :undo_reaction, :article do
      arg(:id, non_null(:id))
      arg(:thread, non_null(:cms_thread))
      arg(:action, non_null(:cms_action))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.undo_reaction/3)
    end
  end
end
