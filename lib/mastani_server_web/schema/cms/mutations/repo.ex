defmodule MastaniServerWeb.Schema.CMS.Mutations.Repo do
  @moduledoc """
  CMS mutations for job
  """
  use Helper.GqlSchemaSuite

  object :cms_repo_mutations do
    @desc "create a user"
    field :create_repo, :repo do
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
      resolve(&R.CMS.create_content/3)
    end

    @desc "pin a repo"
    field :pin_repo, :repo do
      arg(:id, non_null(:id))
      arg(:type, :repo_type, default_value: :repo)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->repo.pin")
      resolve(&R.CMS.pin_content/3)
    end

    @desc "unpin a repo"
    field :undo_pin_repo, :repo do
      arg(:id, non_null(:id))
      arg(:type, :repo_type, default_value: :repo)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->repo.undo_pin")
      resolve(&R.CMS.undo_pin_content/3)
    end

    @desc "trash a repo, not delete"
    field :trash_repo, :repo do
      arg(:id, non_null(:id))
      arg(:type, :repo_type, default_value: :repo)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->repo.trash")

      resolve(&R.CMS.trash_content/3)
    end

    @desc "trash a repo, not delete"
    field :undo_trash_repo, :repo do
      arg(:id, non_null(:id))
      arg(:type, :repo_type, default_value: :repo)
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
