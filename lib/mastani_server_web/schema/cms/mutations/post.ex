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
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      # middleware(M.PublishThrottle, interval: 3, hour_limit: 15, day_limit: 30)
      resolve(&R.CMS.create_content/3)
    end

    @desc "pin a post"
    field :pin_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.pin")
      resolve(&R.CMS.pin_post/3)
    end

    @desc "unpin a post"
    field :undo_pin_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.undo_pin")
      resolve(&R.CMS.undo_pin_post/3)
    end

    @desc "trash a post, not delete"
    field :trash_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.trash")

      resolve(&R.CMS.trash_post/3)
    end

    @desc "trash a post, not delete"
    field :undo_trash_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.undo_trash")

      resolve(&R.CMS.undo_trash_post/3)
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

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      middleware(M.Passport, claim: "owner;cms->c?->post.edit")

      resolve(&R.CMS.update_content/3)
    end
  end
end
