defmodule GroupherServerWeb.Schema.CMS.Mutations.Job do
  @moduledoc """
  CMS mutations for job
  """
  use Helper.GqlSchemaSuite
  import GroupherServerWeb.Schema.Helper.Mutations

  object :cms_job_mutations do
    @desc "create a job"
    field :create_job, :job do
      arg(:title, non_null(:string))
      arg(:company, non_null(:string))
      arg(:company_link, :string)
      arg(:body, non_null(:string))
      arg(:community_id, non_null(:id))

      arg(:desc, :string)
      arg(:link_addr, :string)
      arg(:copy_right, :string)

      arg(:thread, :thread, default_value: :job)
      arg(:article_tags, list_of(:id))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      resolve(&R.CMS.create_article/3)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    @desc "update a cms/job"
    field :update_job, :job do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)
      arg(:copy_right, :string)
      arg(:desc, :string)
      arg(:link_addr, :string)

      arg(:company, :string)
      arg(:company_link, :string)
      arg(:article_tags, list_of(:id))

      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :job)
      middleware(M.Passport, claim: "owner;cms->c?->job.edit")

      resolve(&R.CMS.update_article/3)
    end

    article_react_mutations(:job, [
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
