defmodule MastaniServerWeb.Schema.CMS.Mutations.Post do
  @moduledoc """
  CMS mutations for post
  """
  use Helper.GqlSchemaSuite

  object :cms_post_mutations do
    @desc "create a user"
    field :create_post, :post do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:digest, non_null(:string))
      arg(:length, non_null(:integer))
      arg(:link_addr, :string)
      arg(:copy_right, :string)
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:topic, :string, default_value: "posts")
      arg(:tags, list_of(:ids))
      arg(:mention_users, list_of(:ids))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      middleware(M.AddSourceIcon)
      # middleware(M.PublishThrottle, interval: 3, hour_limit: 15, day_limit: 30)
      resolve(&R.CMS.create_content/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "pin a post"
    field :pin_post, :post do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:thread, :post_thread, default_value: :post)
      arg(:topic, :string, default_value: "posts")

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->post.pin")
      resolve(&R.CMS.pin_content/3)
    end

    @desc "unpin a post"
    field :undo_pin_post, :post do
      arg(:id, non_null(:id))
      arg(:thread, :post_thread, default_value: :post)
      arg(:community_id, non_null(:id))
      arg(:topic, :string, default_value: "posts")

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->post.undo_pin")
      resolve(&R.CMS.undo_pin_content/3)
    end

    @desc "trash a post, not delete"
    field :trash_post, :post do
      arg(:id, non_null(:id))
      arg(:thread, :post_thread, default_value: :post)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->post.trash")

      resolve(&R.CMS.trash_content/3)
    end

    @desc "trash a post, not delete"
    field :undo_trash_post, :post do
      arg(:id, non_null(:id))
      arg(:thread, :post_thread, default_value: :post)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->post.undo_trash")

      resolve(&R.CMS.undo_trash_content/3)
    end

    @desc "delete a cms/post"
    # TODO: if post belongs to multi communities, unset instead delete
    field :delete_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      middleware(M.Passport, claim: "owner;cms->c?->post.delete")

      resolve(&R.CMS.delete_content/3)
    end

    @desc "update a cms/post"
    field :update_post, :post do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)
      arg(:copy_right, :string)
      arg(:link_addr, :string)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      middleware(M.Passport, claim: "owner;cms->c?->post.edit")

      resolve(&R.CMS.update_content/3)
    end
  end
end
