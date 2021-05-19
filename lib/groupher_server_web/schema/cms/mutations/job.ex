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
      arg(:company_logo, non_null(:string))
      arg(:company_link, :string)
      arg(:body, non_null(:string))
      arg(:digest, non_null(:string))
      arg(:length, non_null(:integer))
      arg(:community_id, non_null(:id))

      arg(:salary, non_null(:string))
      arg(:exp, non_null(:string))
      arg(:education, non_null(:string))
      arg(:finance, non_null(:string))
      arg(:scale, non_null(:string))
      arg(:field, non_null(:string))

      arg(:desc, :string)
      arg(:link_addr, :string)
      arg(:copy_right, :string)

      arg(:thread, :thread, default_value: :job)
      arg(:article_tags, list_of(:ids))
      arg(:mention_users, list_of(:ids))

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
      arg(:length, :integer)
      arg(:salary, :string)
      arg(:copy_right, :string)
      arg(:desc, :string)
      arg(:link_addr, :string)

      arg(:company, :string)
      arg(:company_logo, :string)
      arg(:company_link, :string)

      arg(:exp, :string)
      arg(:education, :string)
      arg(:field, :string)
      arg(:finance, :string)
      arg(:scale, :string)
      arg(:article_tags, list_of(:ids))

      # ...

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :job)
      middleware(M.Passport, claim: "owner;cms->c?->job.edit")

      resolve(&R.CMS.update_article/3)
    end

    #############
    article_upvote_mutation(:job)
    article_pin_mutation(:job)
    article_mark_delete_mutation(:job)
    article_delete_mutation(:job)
    article_emotion_mutation(:job)
    article_report_mutation(:job)
    #############
  end
end
