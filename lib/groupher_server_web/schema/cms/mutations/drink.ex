defmodule GroupherServerWeb.Schema.CMS.Mutations.Drink do
  @moduledoc """
  CMS mutations for drink
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_drink_mutations do
    @desc "create a drink"
    field :create_drink, :drink do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :drink)
      arg(:article_tags, list_of(:id))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_article/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/drink"
    field :update_drink, :drink do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)

      arg(:article_tags, list_of(:id))
      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :drink)
      middleware(M.Passport, claim: "owner;cms->c?->drink.edit")

      resolve(&R.CMS.update_article/3)
    end

    article_react_mutations(:drink, [
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
