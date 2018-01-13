defmodule MastaniServerWeb.Schema.CMS.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers

  input_object :pagi_input do
    field(:page, :integer, default_value: 1)
    field(:size, :integer, default_value: 20)
  end

  object :cms_queries do
    @desc "get one post"
    field :post, non_null(:post) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.CMS.post/3)
    end

    @desc "get all posts"
    field :posts, non_null(list_of(non_null(:post))) do
      # case error when refresh the schema
      # arg(:filter, :article_filter, default_value: %{first: 20})
      arg(:filter, :article_filter)
      resolve(&Resolvers.CMS.posts/3)
    end

    field :paged_posts, non_null(list_of(non_null(:paged_posts))) do
      arg(:filter, :paged_article_filter)
      resolve(&Resolvers.CMS.posts/3)
    end

    field :favorite_users, non_null(list_of(non_null(:paged_users))) do
      arg(:id, non_null(:id))
      arg(:type, :cms_part, default_value: :post)
      # TODO: tmp
      arg(:filter, :paged_article_filter)
      resolve(&Resolvers.CMS.reaction_users/3)
    end
  end
end
