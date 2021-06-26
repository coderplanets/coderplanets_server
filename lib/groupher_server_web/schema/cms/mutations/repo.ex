defmodule GroupherServerWeb.Schema.CMS.Mutations.Repo do
  @moduledoc """
  CMS mutations for job
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_repo_mutations do
    @desc "create a repo"
    field :create_repo, :repo do
      arg(:title, non_null(:string))
      arg(:owner_name, non_null(:string))
      arg(:owner_url, non_null(:string))
      arg(:repo_url, non_null(:string))

      arg(:desc, non_null(:string))
      arg(:homepage_url, :string)
      arg(:readme, non_null(:string))

      arg(:star_count, non_null(:integer))
      arg(:issues_count, non_null(:integer))
      arg(:prs_count, non_null(:integer))
      arg(:fork_count, non_null(:integer))
      arg(:watch_count, non_null(:integer))

      arg(:license, :string)
      arg(:release_tag, :string)

      arg(:contributors, list_of(:repo_contributor_input))
      arg(:primary_language, non_null(:repo_lang_input))

      arg(:community_id, non_null(:id))
      arg(:thread, :thread, default_value: :repo)
      arg(:article_tags, list_of(:id))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_article/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/repo"
    field :update_repo, :repo do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:owner_name, :string)
      arg(:owner_url, :string)
      arg(:repo_url, :string)

      arg(:desc, :string)
      arg(:homepage_url, :string)
      arg(:readme, :string)

      arg(:star_count, :integer)
      arg(:issues_count, :integer)
      arg(:prs_count, :integer)
      arg(:fork_count, :integer)
      arg(:watch_count, :integer)

      arg(:license, :string)
      arg(:release_tag, :string)

      arg(:contributors, list_of(:repo_contributor_input))
      arg(:primary_language, :repo_lang_input)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :repo)
      middleware(M.Passport, claim: "owner;cms->c?->repo.edit")

      resolve(&R.CMS.update_article/3)
    end

    article_react_mutations(:repo, [
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
