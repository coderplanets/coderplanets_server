defmodule GroupherServerWeb.Schema.CMS.Mutations.Meetup do
  @moduledoc """
  CMS mutations for meetup
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_meetup_mutations do
    @desc "create a meetup"
    field :create_meetup, :meetup do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :meetup)
      arg(:article_tags, list_of(:id))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_article/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/meetup"
    field :update_meetup, :meetup do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)

      arg(:article_tags, list_of(:id))
      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :meetup)
      middleware(M.Passport, claim: "owner;cms->c?->meetup.edit")

      resolve(&R.CMS.update_article/3)
    end

    article_react_mutations(:meetup, [
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
