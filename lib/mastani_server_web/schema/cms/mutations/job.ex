defmodule MastaniServerWeb.Schema.CMS.Mutations.Job do
  @moduledoc """
  CMS mutations for job
  """
  use Helper.GqlSchemaSuite

  object :cms_job_mutations do
    @desc "create a user"
    field :create_job, :job do
      arg(:title, non_null(:string))
      arg(:company, non_null(:string))
      arg(:company_logo, non_null(:string))
      arg(:location, non_null(:string))
      arg(:body, non_null(:string))
      arg(:digest, non_null(:string))
      arg(:length, non_null(:integer))
      arg(:community_id, non_null(:id))
      arg(:link_addr, :string)
      arg(:link_source, :string)

      arg(:thread, :cms_thread, default_value: :job)
      arg(:tags, list_of(:ids))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.create_content/3)
    end

    @desc "delete a job"
    field :delete_job, :job do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :job)
      middleware(M.Passport, claim: "owner;cms->c?->job.delete")

      resolve(&R.CMS.delete_content/3)
    end

    @desc "update a cms/job"
    field :update_job, :job do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)
      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :job)
      middleware(M.Passport, claim: "owner;cms->c?->job.edit")

      resolve(&R.CMS.update_content/3)
    end
  end
end
