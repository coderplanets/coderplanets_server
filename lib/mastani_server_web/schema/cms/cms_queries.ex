defmodule MastaniServerWeb.Schema.CMS.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware, as: M

  object :cms_queries do
    field :communities, list_of(:community) do
      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.communities/3)
    end

    field :community_subscribers, :paged_users do
      arg(:id, non_null(:id))
      arg(:filter, :paged_article_filter)

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.community_subscribers/3)
      middleware(M.FormatPagination)
    end

    @desc "get one post"
    field :post, non_null(:post) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.CMS.post/3)
    end

    @desc "get all posts"
    field :posts, list_of(:post) do
      # case error when refresh the schema
      # arg(:filter, :article_filter, default_value: %{first: 20})
      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.posts/3)
    end

    field :paged_posts, :paged_posts do
      arg(:filter, non_null(:paged_article_filter))
      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.posts/3)
      middleware(M.FormatPagination)
    end

    field :favorite_users, :paged_users do
      arg(:id, non_null(:id))
      arg(:type, :cms_part, default_value: :post)
      arg(:action, :favorite_action, default_value: :favorite)
      arg(:filter, :paged_article_filter)

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.reaction_users/3)
      middleware(M.FormatPagination)
    end

    field :tags, list_of(:tag) do
      arg(:community, non_null(:string))
      arg(:part, non_null(:community_part_enum))
      resolve(&Resolvers.CMS.get_tags/3)
    end
  end
end
