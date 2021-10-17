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

    @desc "set a article_tag to content"
    field :set_article_tag, :article_tag do
      arg(:id, non_null(:id))
      arg(:article_tag_id, non_null(:id))
      # community_id only use for passport check
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.article_tag.set")

      resolve(&R.CMS.set_article_tag/3)
    end

    @desc "unset a tag to content"
    field :unset_article_tag, :article_tag do
      arg(:id, non_null(:id))
      arg(:article_tag_id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.article_tag.unset")

      resolve(&R.CMS.unset_article_tag/3)
    end

    @desc "mirror article to other community"
    field :mirror_article, :article do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :post)
      arg(:article_tags, list_of(:id), default_value: [])

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->t?.community.mirror")
      resolve(&R.CMS.mirror_article/3)
    end

    @desc "unmirror article to other community"
    field :unmirror_article, :article do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->t?.community.unmirror")
      resolve(&R.CMS.unmirror_article/3)
    end

    @desc "move article to other community"
    field :move_article, :article do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :post)
      arg(:article_tags, list_of(:id), default_value: [])

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->t?.community.move")
      resolve(&R.CMS.move_article/3)
    end

    @desc "mirror article to home community"
    field :mirror_to_home, :article do
      arg(:id, non_null(:id))
      arg(:thread, :thread, default_value: :post)
      arg(:article_tags, list_of(:id), default_value: [])

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->homemirror")
      resolve(&R.CMS.mirror_to_home/3)
    end

    @desc "move article to other community"
    field :move_to_blackhole, :article do
      arg(:id, non_null(:id))
      arg(:thread, :thread, default_value: :post)
      arg(:article_tags, list_of(:id), default_value: [])

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->blackeye")
      resolve(&R.CMS.move_to_blackhole/3)
    end
  end
end
