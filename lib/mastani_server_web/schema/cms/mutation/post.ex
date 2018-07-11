defmodule MastaniServerWeb.Schema.CMS.Mutation.Post do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.{Resolvers}
  alias MastaniServerWeb.Middleware, as: M

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
      resolve(&Resolvers.CMS.create_content/3)
    end

    @desc "pin a post"
    field :pin_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.pin")
      resolve(&Resolvers.CMS.pin_post/3)
    end

    @desc "unpin a post"
    field :undo_pin_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.undo_pin")
      resolve(&Resolvers.CMS.undo_pin_post/3)
    end

    @desc "trash a post, not delete"
    field :trash_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.trash")

      resolve(&Resolvers.CMS.trash_post/3)
    end

    @desc "trash a post, not delete"
    field :undo_trash_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->post.undo_trash")

      resolve(&Resolvers.CMS.undo_trash_post/3)
    end

    @desc "delete a cms/post"
    # TODO: if post belongs to multi communities, unset instead delete
    field :delete_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      middleware(M.Passport, claim: "owner;cms->c?->post.delete")

      resolve(&Resolvers.CMS.delete_content/3)
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

      resolve(&Resolvers.CMS.update_content/3)
    end
  end
end
