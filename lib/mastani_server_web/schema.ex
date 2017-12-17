defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema

  alias MastaniServerWeb.NewsResolver
  alias MastaniServerWeb.Resolvers

  object :link do
    field(:id, non_null(:id))
    field(:url, non_null(:string))
    field(:description, non_null(:string))
  end

  object :user do
    field(:id, non_null(:id))
    field(:username, non_null(:string))
    field(:nickname, non_null(:string))
    field(:bio, non_null(:string))
    field(:company, non_null(:string))
  end

  query do
    @desc "hehehef: Get all links"
    field :all_links, non_null(list_of(non_null(:link))) do
      resolve(&NewsResolver.all_links/3)
    end

    @desc "hehehef: Get all links"
    field :all_users, non_null(list_of(non_null(:user))) do
      resolve(&Resolvers.Accounts.all_users/3)
    end
  end

  mutation do
    field :create_link, :link do
      arg(:url, non_null(:string))
      arg(:description, non_null(:string))

      resolve(&NewsResolver.create_link/3)
    end
  end
end
