defmodule GroupherServerWeb.Schema.CMS.Mutations.Works do
  @moduledoc """
  CMS mutations for works
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_works_mutations do
    @desc "create a works"
    field :create_works, :works do
      arg(:cover, non_null(:string))
      arg(:title, non_null(:string))
      arg(:desc, non_null(:string))
      arg(:home_link, non_null(:string))
      arg(:body, non_null(:string))
      # not for resolver, is for middleware
      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :works)
      arg(:article_tags, list_of(:id))

      arg(:techstacks, list_of(:string))
      arg(:teammates, list_of(:string))
      arg(:cities, list_of(:string))

      arg(:profit_mode, :profit_mode)
      arg(:working_mode, :working_mode)

      arg(:social_info, list_of(:social_info))
      arg(:app_store, list_of(:app_store_info))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_works/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/works"
    field :update_works, :works do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:cover, :string)
      arg(:desc, :string)
      arg(:home_link, :string)
      arg(:body, :string)

      arg(:article_tags, list_of(:id))

      arg(:techstacks, list_of(:string))
      arg(:teammates, list_of(:string))
      arg(:cities, list_of(:string))

      arg(:profit_mode, :profit_mode)
      arg(:working_mode, :working_mode)

      arg(:social_info, list_of(:social_info))
      arg(:app_store, list_of(:app_store_info))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :works)
      middleware(M.Passport, claim: "owner;cms->c?->works.edit")

      resolve(&R.CMS.update_works/3)
    end

    article_react_mutations(:works, [
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
