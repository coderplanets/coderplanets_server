defmodule MastaniServerWeb.Schema.CMS.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware, as: M

  object :cms_queries do
    field :community, :community do
      # arg(:id, non_null(:id))
      arg(:id, :id)
      arg(:title, :string)
      resolve(&Resolvers.CMS.community/3)
    end

    field :paged_communities, :paged_communities do
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.paged_communities/3)
      middleware(M.FormatPagination)
    end

    # TODO: remove
    field :communities, :paged_communities do
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.paged_communities/3)
      middleware(M.FormatPagination)
    end

    @desc "paged subscribers of a community"
    field :community_subscribers, :paged_users do
      arg(:id, non_null(:id))
      arg(:filter, :paged_filter)

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.community_subscribers/3)
      middleware(M.FormatPagination)
    end

    @desc "paged subscribers of a community"
    field :community_editors, :paged_users do
      arg(:id, non_null(:id))
      arg(:filter, :paged_filter)

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.community_editors/3)
      middleware(M.FormatPagination)
    end

    @desc "get all categories"
    field :paged_categories, :paged_categories do
      arg(:filter, :paged_filter)

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.paged_categories/3)
      middleware(M.FormatPagination)
    end

    @desc "get one post"
    field :post, non_null(:post) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.CMS.post/3)
    end

    @desc "get paged posts"
    field :paged_posts, :paged_posts do
      arg(:filter, non_null(:paged_article_filter))
      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.paged_posts/3)
      middleware(M.FormatPagination)
    end

    @desc "get one job"
    field :job, non_null(:job) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.CMS.job/3)
    end

    @desc "get paged jobs"
    field :paged_jobs, :paged_jobs do
      arg(:filter, non_null(:paged_article_filter))

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.paged_jobs/3)
      middleware(M.FormatPagination)
    end

    field :favorite_users, :paged_users do
      arg(:id, non_null(:id))
      arg(:type, :cms_thread, default_value: :post)
      arg(:action, :favorite_action, default_value: :favorite)
      arg(:filter, :paged_article_filter)

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.reaction_users/3)
      middleware(M.FormatPagination)
    end

    # get all tags
    field :paged_tags, :paged_tags do
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.get_tags/3)
      middleware(M.FormatPagination)
    end

    # TODO: remove
    field :tags, :paged_tags do
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      # TODO: should be passport
      resolve(&Resolvers.CMS.get_tags/3)
      middleware(M.FormatPagination)
    end

    # partial
    field :partial_tags, list_of(:tag) do
      arg(:community, non_null(:string))
      arg(:thread, non_null(:community_thread_enum))

      resolve(&Resolvers.CMS.get_tags/3)
    end

    @desc "get paged comments"
    field :paged_comments, :paged_comments do
      arg(:id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:filter, :comments_filter)

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.paged_comments/3)
      middleware(M.FormatPagination)
    end

    # comments
    field :comments, :paged_comments do
      arg(:id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:filter, :comments_filter)

      middleware(M.PageSizeProof)
      resolve(&Resolvers.CMS.paged_comments/3)
      middleware(M.FormatPagination)
    end
  end
end
