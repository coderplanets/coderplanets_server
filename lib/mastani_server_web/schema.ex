defmodule MastaniServerWeb.Schema do
  @moduledoc """
  scham index
  """
  use Absinthe.Schema
  # use ApolloTracing

  alias MastaniServerWeb.Middleware, as: M
  alias MastaniServerWeb.Schema.{Account, Billing, CMS, Delivery, Statistics, Utils}

  import_types(Absinthe.Type.Custom)

  # utils
  import_types(Utils.CommonTypes)

  # account
  import_types(Account.Types)
  import_types(Account.Queries)
  import_types(Account.Mutations)

  # billing
  import_types(Billing.Types)
  import_types(Billing.Queries)
  import_types(Billing.Mutations)

  # statistics
  import_types(Statistics.Types)
  import_types(Statistics.Queries)
  import_types(Statistics.Mutations)

  # delivery
  import_types(Delivery.Types)
  import_types(Delivery.Queries)
  import_types(Delivery.Mutations)

  # cms
  import_types(CMS.Types)
  import_types(CMS.Queries)
  import_types(CMS.Mutations.Community)
  import_types(CMS.Mutations.Operation)
  import_types(CMS.Mutations.Post)
  import_types(CMS.Mutations.Job)
  import_types(CMS.Mutations.Video)
  import_types(CMS.Mutations.Repo)
  import_types(CMS.Mutations.Comment)

  query do
    import_fields(:account_queries)
    import_fields(:billing_queries)
    import_fields(:statistics_queries)
    import_fields(:delivery_queries)
    import_fields(:cms_queries)
  end

  mutation do
    # account
    import_fields(:account_mutations)
    # billing
    import_fields(:billing_mutations)
    # statistics
    import_fields(:statistics_mutations)
    # delivery
    import_fields(:delivery_mutations)
    # cms
    import_fields(:cms_mutation_community)
    import_fields(:cms_opertion_mutations)
    import_fields(:cms_post_mutations)
    import_fields(:cms_job_mutations)
    import_fields(:cms_video_mutations)
    import_fields(:cms_repo_mutations)

    import_fields(:cms_comment_mutations)
  end

  def middleware(middleware, _field, %{identifier: :query}) do
    middleware ++ [M.GeneralError]
  end

  def middleware(middleware, _field, %{identifier: :mutation}) do
    middleware ++ [M.ChangesetErrors]
  end

  def middleware(middleware, _field, _object) do
    [ApolloTracing.Middleware.Tracing, ApolloTracing.Middleware.Caching] ++ middleware
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def dataloader do
    alias MastaniServer.{Accounts, CMS}

    Dataloader.new()
    |> Dataloader.add_source(Accounts, Accounts.Utils.Loader.data())
    |> Dataloader.add_source(CMS, CMS.Utils.Loader.data())
  end

  def context(ctx) do
    ctx |> Map.put(:loader, dataloader())
  end
end
