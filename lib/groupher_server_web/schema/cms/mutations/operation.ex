defmodule GroupherServerWeb.Schema.CMS.Mutations.Operation do
  @moduledoc """
  CMS mutations for cms operations
  """
  use Helper.GqlSchemaSuite

  object :cms_opertion_mutations do
    @desc "set category to a community"
    field :set_category, :community do
      arg(:community_id, non_null(:id))
      arg(:category_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->category.set")

      resolve(&R.CMS.set_category/3)
    end

    @desc "unset category to a community"
    field :unset_category, :community do
      arg(:community_id, non_null(:id))
      arg(:category_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->category.unset")

      resolve(&R.CMS.unset_category/3)
    end

    @desc "bind a thread to a exist community"
    field :set_thread, :community do
      arg(:community_id, non_null(:id))
      arg(:thread_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->thread.set")

      resolve(&R.CMS.set_thread/3)
    end

    @desc "remove a thread from a exist community, thread content is not delete"
    field :unset_thread, :community do
      arg(:community_id, non_null(:id))
      arg(:thread_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->thread.unset")

      resolve(&R.CMS.unset_thread/3)
    end

    @desc "stamp rules on user's passport"
    field :stamp_cms_passport, :idlike do
      arg(:user_id, non_null(:id))
      arg(:rules, non_null(:json))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.stamp_passport")

      resolve(&R.CMS.stamp_passport/3)
    end

    @desc "subscribe a community so it can appear in sidebar"
    field :subscribe_community, :community do
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.subscribe_community/3)
    end

    @desc "unsubscribe a community"
    field :unsubscribe_community, :community do
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.unsubscribe_community/3)
    end

    @desc "set a tag to content"
    field :set_tag, :tag do
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      # community_id only use for passport check
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.tag.set")

      resolve(&R.CMS.set_tag/3)
    end

    @desc "set a refined tag to content"
    field :set_refined_tag, :tag do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.refinedtag.set")

      resolve(&R.CMS.set_refined_tag/3)
    end

    @desc "unset a tag to content"
    field :unset_tag, :tag do
      # thread id
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.tag.unset")

      resolve(&R.CMS.unset_tag/3)
    end

    @desc "unset a refined tag to content"
    field :unset_refined_tag, :tag do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.refinedtag.set")

      resolve(&R.CMS.unset_refined_tag/3)
    end

    # TODO: use community loader
    field :set_community, :community do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->t?.community.set")
      resolve(&R.CMS.set_community/3)
    end

    # TODO: can't not unset the oldest community
    field :unset_community, :community do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->t?.community.unset")
      resolve(&R.CMS.unset_community/3)
    end

    @desc "react on a cms content, except favorite"
    field :reaction, :article do
      arg(:id, non_null(:id))
      arg(:thread, non_null(:react_thread))
      arg(:action, non_null(:reactable_action))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.reaction/3)
    end

    @desc "undoreact on a cms content"
    field :undo_reaction, :article do
      arg(:id, non_null(:id))
      arg(:thread, non_null(:react_thread))
      arg(:action, non_null(:reactable_action))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.undo_reaction/3)
    end
  end
end
