defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema
  alias MastaniServerWeb.Schema

  import_types(Absinthe.Type.Custom)

  import_types(Schema.AccountTypes)
  import_types(Schema.AccountOps)
  import_types(Schema.CMSTypes)
  import_types(Schema.CMSOps)

  query do
    import_fields(:account_queries)
    import_fields(:cms_post_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:cms_post_mutations)
  end
end
