defmodule MastaniServerWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  alias MastaniServerWeb.Resolvers.Accounts

  object :page_info do
    field(:total_count, :integer)
    field(:page_size, :integer)
  end

  object :user do
    field(:id, non_null(:id))
    field(:username, non_null(:string))
    field(:nickname, non_null(:string))
    field(:bio, non_null(:string))
    field(:company, non_null(:string))
    field(:page_info, :page_info)
  end

  object :paged_users do
    field(:entries, non_null(list_of(non_null(:user))))
    field(:total_count, :integer)
    field(:page_size, :integer)
  end

  object :account_queries do
    @desc "hehehef: Get all links"
    field :all_users, non_null(list_of(non_null(:user))) do
      resolve(&Accounts.all_users/3)
    end

    field :all_users2, non_null(:paged_users) do
      resolve(&Accounts.all_users2/3)
    end
  end

  object :account_mutations do
    @desc "hehehef: create a user"
    field :create_user, :user do
      arg(:username, non_null(:string))
      arg(:nickname, non_null(:string))
      arg(:bio, non_null(:string))
      arg(:company, non_null(:string))

      resolve(&Accounts.create_user/3)
    end
  end
end
