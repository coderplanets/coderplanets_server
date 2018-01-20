defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema
  alias MastaniServerWeb.Schema

  import_types(Absinthe.Type.Custom)

  import_types(Schema.Account.Types)
  import_types(Schema.Account.Queries)
  import_types(Schema.Account.Mutations)

  import_types(Schema.CMS.Types)
  import_types(Schema.CMS.Queries)
  import_types(Schema.CMS.Mutations)

  query do
    import_fields(:account_queries)
    import_fields(:cms_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:cms_mutations)
  end
end
