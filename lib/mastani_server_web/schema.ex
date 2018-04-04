defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema

  alias MastaniServerWeb.Schema.{Account, CMS, Statistics, Tmp}
  alias MastaniServerWeb.Middleware, as: M

  import_types(Absinthe.Type.Custom)

  import_types(Account.Types)
  import_types(Account.Queries)
  import_types(Account.Mutations)

  import_types(CMS.Types)
  import_types(CMS.Queries)
  import_types(CMS.Mutations)

  import_types(Statistics.Types)
  import_types(Statistics.Queries)
  import_types(Statistics.Mutations)

  query do
    import_fields(:account_queries)
    import_fields(:cms_queries)
    import_fields(:statistics_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:cms_mutations)
    import_fields(:statistics_mutations)
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

  def dataloader() do
    alias MastaniServer.{Accounts, CMS}

    Dataloader.new()
    |> Dataloader.add_source(Accounts, Accounts.data())
    |> Dataloader.add_source(CMS, CMS.data())
  end

  def context(ctx) do
    ctx
    |> Map.put(:loader, dataloader())
  end
end
