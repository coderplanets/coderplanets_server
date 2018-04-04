defmodule MastaniServerWeb.Schema.Tmp.PassportTestQueries do
  @moduledoc """
  this module is mainly used for test the Passport middleware
  NOT for endpoint user
  if you have a better way to test middleware, please let me know
  """
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware, as: M

  object :passport_test_queries do
    # @desc "DO NOT CALL, this is only for test passport"
    field :passport_delete_post, non_null(:post) do
      arg(:id, non_null(:id))

      # arg(:id, non_null(:id))
      # Loader 应该 “约定” 的从 args 或者 owner 的第一个匹配参数 或者 preload community 的 title 以及 rules
      # middleware(M.PassportLoader, preload: :community, owner: :post)

      # middleware(M.PassportLoader)
      # middleware(M.PassportLoader, owner: :post)
      # TODO: login check

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post, base: :communities)
      # middleware(M.PassportLoader, owner: :post, base: :community, managers: ...)
      # middleware(Middleware.OwnerRequired, match: [:post, :tag])
      # middleware(M.Passport, claim: "owner;cms->c?->post.articles.edit")
      middleware(M.Passport, claim: "cms->c?->post.article.delete")
      resolve(&Resolvers.CMS.delete_post/3)
    end

    field :passport_delete_post2, non_null(:post) do
      arg(:id, non_null(:id))
      # arg(:community, non_null(:string))

      middleware(M.PassportLoader, source: :post, base: :communities)
      middleware(M.Passport, claim: "owner;cms->c?->post.article.delete")
      resolve(&Resolvers.CMS.post/3)
    end
  end
end

#
