defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema
  alias MastaniServerWeb.Schema.{Account, CMS}
  alias MastaniServerWeb.Middleware

  import_types(Absinthe.Type.Custom)

  import_types(Account.Types)
  import_types(Account.Queries)
  import_types(Account.Mutations)

  import_types(CMS.Types)
  import_types(CMS.Queries)
  import_types(CMS.Mutations)

  query do
    import_fields(:account_queries)
    import_fields(:cms_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:cms_mutations)
  end

  def middleware(middleware, _field, %{identifier: :query}) do
    middleware ++ [Middleware.GeneralError]
  end

  def middleware(middleware, _field, %{identifier: :mutation}) do
    middleware ++ [Middleware.ChangesetErrors] ++ [Middleware.GeneralError]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def dataloader() do
    alias MastaniServer.{CMS}

    Dataloader.new()
    |> Dataloader.add_source(CMS, CMS.data())
  end

  def context(ctx) do
    ctx
    |> Map.put(:loader, dataloader())
  end
end
