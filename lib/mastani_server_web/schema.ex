defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema
  alias MastaniServerWeb.Schema.{Account, CMS, Middleware}
  # alias MastaniServerWeb.Schema.Middleware

  def middleware(middleware, _field, %{identifier: :query}) do
    middleware ++ [Middleware.ChangesetErrors]
  end

  def middleware(middleware, _field, %{identifier: :mutation}) do
    # middleware |> IO.inspect(label: 'middleware')
    # field |> IO.inspect(label: 'field')
    # object |> IO.inspect(label: 'object')

    # middleware
    middleware ++ [Middleware.ChangesetErrors]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

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
end
