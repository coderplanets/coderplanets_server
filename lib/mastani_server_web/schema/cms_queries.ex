defmodule MastaniServerWeb.Schema.CMS.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers

  enum :cms_part do
    value(:post)
    value(:job)
    value(:meetup)
  end

  # input_object :pagi do
  # field :page, :integer, default_value: 1
  # field :size, :integer, default_value: 20
  # end

  object :cms_queries do
    @desc "hehehef: Get all links"
    field :all_posts, non_null(list_of(non_null(:post))) do
      resolve(&Resolvers.CMS.all_posts/3)
    end

    field :favorite_users, non_null(list_of(non_null(:paged_users))) do
      arg(:type, :cms_part, default_value: :post)
      arg(:id, non_null(:id))

      arg(:page, :integer, default_value: 1)
      arg(:size, :integer, default_value: 20)

      resolve(&Resolvers.CMS.reaction_users/3)
    end
  end
end
