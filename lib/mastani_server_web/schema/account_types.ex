defmodule MastaniServerWeb.Schema.Account.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

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
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :paged_users do
    field(:entries, non_null(list_of(non_null(:user))))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end
end
