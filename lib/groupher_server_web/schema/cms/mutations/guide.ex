defmodule GroupherServerWeb.Schema.CMS.Mutations.Guide do
  @moduledoc """
  CMS mutations for guide
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_guide_mutations do
    @desc "create a guide"
    field :create_guide, :guide do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :guide)
      arg(:article_tags, list_of(:id))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_article/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/guide"
    field :update_guide, :guide do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)

      arg(:article_tags, list_of(:id))
      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :guide)
      middleware(M.Passport, claim: "owner;cms->c?->guide.edit")

      resolve(&R.CMS.update_article/3)
    end

    article_react_mutations(:guide, [
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
