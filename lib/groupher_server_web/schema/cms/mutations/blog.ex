defmodule GroupherServerWeb.Schema.CMS.Mutations.Blog do
  @moduledoc """
  CMS mutations for blog
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_blog_mutations do
    @desc "create a blog"
    field :create_blog, :blog do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:digest, non_null(:string))
      arg(:community_id, non_null(:id))
      arg(:link_addr, :string)
      arg(:thread, :thread, default_value: :blog)
      arg(:article_tags, list_of(:id))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_article/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/blog"
    field :update_blog, :blog do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)
      arg(:link_addr, :string)

      arg(:article_tags, list_of(:id))

      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :blog)
      middleware(M.Passport, claim: "owner;cms->c?->blog.edit")

      resolve(&R.CMS.update_article/3)
    end

    article_react_mutations(:blog, [
      :upvote,
      :pin,
      :mark_delete,
      :delete,
      :emotion,
      :report,
      :sink,
      :lock_comment
    ])
  end
end
