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
      arg(:community, non_null(:string))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.create_post/3)
    end

    @desc "delete a cms/post"
    field :delete_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      middleware(M.Passport, claim: "owner;cms->c?->post.article.delete")

      resolve(&Resolvers.CMS.delete_post/3)
    end

    @desc "update a cms/post"
    field :update_post, :post do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)

      middlewared(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      middleware(M.Passport, claim: "owner;cms->c?->post.article.edit")

      resolve(&Resolvers.CMS.update_post/3)
    end
  end
end
