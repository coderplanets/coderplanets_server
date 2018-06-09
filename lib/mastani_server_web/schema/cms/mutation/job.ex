defmodule MastaniServerWeb.Schema.CMS.Mutation.Job do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.{Resolvers}
  alias MastaniServerWeb.Middleware, as: M

  object :cms_mutation_job do
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

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.create_content/3)
    end

    @desc "delete a job"
    field :delete_job, :job do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :job)
      middleware(M.Passport, claim: "owner;cms->c?->job.delete")

      resolve(&Resolvers.CMS.delete_content/3)
    end

    @desc "update a cms/post"
    field :update_job, :job do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)
      # ...

      middlewared(M.Authorize, :login)
      middleware(M.PassportLoader, source: :job)
      middleware(M.Passport, claim: "owner;cms->c?->job.edit")

      resolve(&Resolvers.CMS.update_content/3)
    end
  end
end
