defmodule GroupherServerWeb.Schema.CMS.Mutations.Community do
  @moduledoc """
  CMS mations for community
  """
  use Helper.GqlSchemaSuite

  object :cms_mutation_community do
    @desc "create a global community"
    field :create_community, :community do
      arg(:title, non_null(:string))
      arg(:desc, non_null(:string))
      arg(:raw, non_null(:string))
      arg(:logo, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.create")

      resolve(&R.CMS.create_community/3)
      middleware(M.Statistics.MakeContribute, for: [:user])
    end

    @desc "update a community"
    field :update_community, :community do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:desc, :string)
      arg(:raw, :string)
      arg(:logo, :string)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.update")

      resolve(&R.CMS.update_community/3)
    end

    @desc "delete a global community"
    field :delete_community, :community do
      arg(:id, non_null(:id))
      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.delete")

      resolve(&R.CMS.delete_community/3)
    end

    @desc "apply to create a community"
    field :apply_community, :community do
      arg(:title, non_null(:string))
      arg(:desc, non_null(:string))
      arg(:raw, non_null(:string))
      arg(:logo, non_null(:string))
      arg(:apply_msg, :string)
      arg(:apply_category, :string)

      middleware(M.Authorize, :login)
      resolve(&R.CMS.apply_community/3)
    end

    @desc "approve the apply to create a community"
    field :approve_community_apply, :community do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.apply.approve")
      resolve(&R.CMS.approve_community_apply/3)
    end

    @desc "deny the apply to create a community"
    field :deny_community_apply, :community do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.apply.deny")
      resolve(&R.CMS.deny_community_apply/3)
    end

    @desc "create category"
    field :create_category, :category do
      arg(:title, non_null(:string))
      arg(:raw, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->category.create")

      resolve(&R.CMS.create_category/3)
    end

    @desc "delete category"
    field :delete_category, :category do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->category.delete")

      resolve(&R.CMS.delete_category/3)
    end

    @desc "update category"
    field :update_category, :category do
      arg(:id, non_null(:id))
      arg(:title, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->category.update")

      resolve(&R.CMS.update_category/3)
    end

    @desc "create independent thread"
    field :create_thread, :thread_item do
      arg(:title, non_null(:string))
      arg(:raw, non_null(:string))
      arg(:index, :integer, default_value: 0)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->thread.create")

      resolve(&R.CMS.create_thread/3)
    end

    @desc "add a editor for a community"
    field :set_editor, :user do
      arg(:community_id, non_null(:id))
      arg(:user_id, non_null(:id))
      arg(:title, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->editor.set")

      resolve(&R.CMS.set_editor/3)
    end

    @desc "unset a editor from a community, the user's passport also deleted"
    field :unset_editor, :user do
      arg(:community_id, non_null(:id))
      arg(:user_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->editor.unset")

      resolve(&R.CMS.unset_editor/3)
    end

    # TODO: remove, should remove both editor and cms->passport
    @desc "update cms editor's title, passport is not effected"
    field :update_cms_editor, :user do
      arg(:community_id, non_null(:id))
      arg(:user_id, non_null(:id))
      arg(:title, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->editor.update")

      resolve(&R.CMS.update_editor/3)
    end

    @desc "create a tag"
    field :create_article_tag, :article_tag do
      arg(:title, non_null(:string))
      arg(:raw, non_null(:string))
      arg(:color, non_null(:rainbow_color))
      arg(:community_id, non_null(:id))
      arg(:group, :string)
      arg(:thread, :thread, default_value: :post)
      arg(:extra, list_of(:string))
      arg(:icon, :string)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.article_tag.create")

      resolve(&R.CMS.create_article_tag/3)
    end

    @desc "update a tag"
    field :update_article_tag, :article_tag do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:title, :string)
      arg(:raw, :string)
      arg(:color, :rainbow_color)
      arg(:group, :string)
      arg(:thread, :thread, default_value: :post)
      arg(:extra, list_of(:string))
      arg(:icon, :string)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.article_tag.update")

      resolve(&R.CMS.update_article_tag/3)
    end

    @desc "delete a tag by thread"
    field :delete_article_tag, :article_tag do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->t?.article_tag.delete")

      resolve(&R.CMS.delete_article_tag/3)
    end

    @desc "sync github wiki"
    field :sync_wiki, :wiki do
      arg(:community_id, non_null(:id))
      arg(:readme, non_null(:string))
      arg(:last_sync, non_null(:datetime))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.sync_wiki/3)
    end

    @desc "add contributor to wiki "
    field :add_wiki_contributor, :wiki do
      arg(:id, non_null(:id))
      arg(:contributor, non_null(:github_contributor_input))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.add_wiki_contributor/3)
    end

    @desc "sync github  cheatsheets "
    field :sync_cheatsheet, :cheatsheet do
      arg(:community_id, non_null(:id))
      arg(:readme, non_null(:string))
      arg(:last_sync, non_null(:datetime))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.sync_cheatsheet/3)
    end

    @desc "add contributor to cheatsheets"
    field :add_cheatsheet_contributor, :cheatsheet do
      arg(:id, non_null(:id))
      arg(:contributor, non_null(:github_contributor_input))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.add_cheatsheet_contributor/3)
    end
  end
end
