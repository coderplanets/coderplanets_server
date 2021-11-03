defmodule GroupherServerWeb.Schema.CMS.Mutations.Radar do
  @moduledoc """
  CMS mutations for radar
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_radar_mutations do
    @desc "create a radar"
    field :create_radar, :radar do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:link_addr, non_null(:string))
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :radar)
      arg(:article_tags, list_of(:id))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_article/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/radar"
    field :update_radar, :radar do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)
      arg(:link_addr, :string)

      arg(:article_tags, list_of(:id))
      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :radar)
      middleware(M.Passport, claim: "owner;cms->c?->radar.edit")

      resolve(&R.CMS.update_article/3)
    end

    article_react_mutations(:radar, [
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
