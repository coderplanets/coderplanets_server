defmodule MastaniServerWeb.Schema.CMS.Mutation.Post do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.{Resolvers}
  alias MastaniServerWeb.Middleware, as: M

  object :cms_mutation_post do
    @desc "create a user"
    field :create_post, :post do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:digest, non_null(:string))
      arg(:length, non_null(:integer))
      arg(:link_addr, :string)
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.create_content/3)
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

      middlewared(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      # TODO: remove article
      middleware(M.Passport, claim: "owner;cms->c?->post.edit")

      resolve(&Resolvers.CMS.update_content/3)
    end
  end
end
