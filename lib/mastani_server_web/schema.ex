defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom
  import_types MastaniServerWeb.Schema.AccountTypes

  alias MastaniServerWeb.Resolvers

  object :link do
    field(:id, non_null(:id))
    field(:url, non_null(:string))
    field(:description, non_null(:string))
  end

  query do
    @desc "hehehef: Get all links"
    field :all_links, non_null(list_of(non_null(:link))) do
      # resolve(&NewsResolver.all_links/3)
      resolve(&Resolvers.News.all_links/3)
    end

    import_fields :account_queries
  end

  mutation do
    field :create_link, :link do
      arg(:url, non_null(:string))
      arg(:description, non_null(:string))

      resolve(&Resolvers.News.create_link/3)
    end

    import_fields :account_mutations

  end
end
