defmodule GroupherServerWeb.Schema.CMS.Mutations.Works do
  @moduledoc """
  CMS mutations for works
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_works_mutations do
    @desc "create a works"
    field :create_works, :works do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:digest, non_null(:string))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :works)
      arg(:article_tags, list_of(:id))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_article/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/works"
    field :update_works, :works do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)

      arg(:article_tags, list_of(:id))
      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :works)
      middleware(M.Passport, claim: "owner;cms->c?->works.edit")

      resolve(&R.CMS.update_article/3)
    end

    #############
    article_upvote_mutation(:works)
    article_pin_mutation(:works)
    article_mark_delete_mutation(:works)
    article_delete_mutation(:works)
    article_emotion_mutation(:works)
    article_report_mutation(:works)
    article_sink_mutation(:works)
    article_lock_comment_mutation(:works)
    #############
  end
end
