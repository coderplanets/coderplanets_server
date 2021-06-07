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
      arg(:length, non_null(:integer))
      arg(:community_id, non_null(:id))

      arg(:link_addr, :string)

      arg(:thread, :thread, default_value: :blog)
      arg(:article_tags, list_of(:ids))

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
      arg(:length, :integer)
      arg(:link_addr, :string)

      arg(:company, :string)
      arg(:company_link, :string)
      arg(:article_tags, list_of(:ids))

      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :blog)
      middleware(M.Passport, claim: "owner;cms->c?->blog.edit")

      resolve(&R.CMS.update_article/3)
    end

    #############
    article_upvote_mutation(:blog)
    article_pin_mutation(:blog)
    article_mark_delete_mutation(:blog)
    article_delete_mutation(:blog)
    article_emotion_mutation(:blog)
    article_report_mutation(:blog)
    article_sink_mutation(:blog)
    article_lock_comment_mutation(:blog)
    #############
  end
end
