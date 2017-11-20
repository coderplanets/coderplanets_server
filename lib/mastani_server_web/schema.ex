defmodule MastaniServerWeb.Schema do
  use Absinthe.Schema

  alias MastaniServerWeb.NewsResolver

  object :link do
    field :id, non_null(:id)
    field :url, non_null(:string)
    field :description, non_null(:string)
  end

  query do
    field :all_links, non_null(list_of(non_null(:link))) do
      resolve &NewsResolver.all_links/3
    end
  end
end
