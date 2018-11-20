defmodule MastaniServerWeb.Schema.CMS.Mutations.Repo do
  @moduledoc """
  CMS mutations for job
  """
  use Helper.GqlSchemaSuite

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
      arg(:thread, :cms_thread, default_value: :repo)
      arg(:tags, list_of(:ids))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)

      resolve(&R.CMS.create_content/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "pin a repo"
    field :pin_repo, :repo do
      arg(:id, non_null(:id))
      arg(:thread, :repo_thread, default_value: :repo)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->repo.pin")
      resolve(&R.CMS.pin_content/3)
    end

    @desc "unpin a repo"
    field :undo_pin_repo, :repo do
      arg(:id, non_null(:id))
      arg(:thread, :repo_thread, default_value: :repo)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->repo.undo_pin")
      resolve(&R.CMS.undo_pin_content/3)
    end

    @desc "trash a repo, not delete"
    field :trash_repo, :repo do
      arg(:id, non_null(:id))
      arg(:thread, :repo_thread, default_value: :repo)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->repo.trash")

      resolve(&R.CMS.trash_content/3)
    end

    @desc "trash a repo, not delete"
    field :undo_trash_repo, :repo do
      arg(:id, non_null(:id))
      arg(:thread, :repo_thread, default_value: :repo)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->repo.undo_trash")

      resolve(&R.CMS.undo_trash_content/3)
    end

    @desc "delete a repo"
    field :delete_repo, :repo do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :repo)
      middleware(M.Passport, claim: "owner;cms->c?->repo.delete")

      resolve(&R.CMS.delete_content/3)
    end

    @desc "update a cms/repo"
    field :update_repo, :repo do
      arg(:repo_name, non_null(:string))
      arg(:desc, non_null(:string))
      arg(:readme, non_null(:string))
      arg(:language, non_null(:string))
      arg(:repo_link, non_null(:string))
      arg(:producer, non_null(:string))
      arg(:producer_link, non_null(:string))

      arg(:repo_star_count, non_null(:integer))
      arg(:repo_fork_count, non_null(:integer))
      arg(:repo_watch_count, non_null(:integer))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :repo)
      middleware(M.Passport, claim: "owner;cms->c?->repo.edit")

      resolve(&R.CMS.update_content/3)
    end
  end
end
