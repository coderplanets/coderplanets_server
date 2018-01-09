defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema
  alias MastaniServerWeb.Schema.{Account, CMS}

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
