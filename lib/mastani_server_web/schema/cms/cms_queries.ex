defmodule MastaniServerWeb.Schema.CMS.Queries do
  @moduledoc """
  CMS queries
  """
  use Helper.GqlSchemaSuite

  object :cms_queries do
    field :community, :community do
      # arg(:id, non_null(:id))
      arg(:id, :id)
      arg(:title, :string)
      arg(:raw, :string)
      resolve(&R.CMS.community/3)
    end

    @desc "communities with pagination info"
    field :paged_communities, :paged_communities do
      arg(:filter, non_null(:communities_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_communities/3)
    end

    @desc "paged subscribers of a community"
    field :community_subscribers, :paged_users do
      arg(:id, non_null(:id))
      arg(:filter, :paged_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.community_subscribers/3)
    end

    @desc "paged subscribers of a community"
    field :community_editors, :paged_users do
      arg(:id, non_null(:id))
      arg(:filter, :paged_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.community_editors/3)
    end

    @desc "get all categories"
    field :paged_categories, :paged_categories do
      arg(:filter, :paged_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_categories/3)
    end

    @desc "get all the threads across all communities"
    field :paged_threads, :paged_threads do
      arg(:filter, :threads_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_threads/3)
    end

    @desc "get post by id"
    field :post, non_null(:post) do
      arg(:id, non_null(:id))
      resolve(&R.CMS.post/3)
    end

    @desc "get paged posts"
    field :paged_posts, :paged_posts do
      arg(:filter, non_null(:paged_article_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_posts/3)
    end

    @desc "get video by id"
    field :video, non_null(:video) do
      arg(:id, non_null(:id))
      resolve(&R.CMS.video/3)
    end

    @desc "get paged videos"
    field :paged_videos, :paged_videos do
      arg(:filter, non_null(:paged_article_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_videos/3)
    end

    @desc "get repo by id"
    field :repo, non_null(:repo) do
      arg(:id, non_null(:id))
      resolve(&R.CMS.repo/3)
    end

    @desc "get paged videos"
    field :paged_repos, :paged_repos do
      arg(:filter, non_null(:paged_article_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_repos/3)
    end

    @desc "get job by id"
    field :job, non_null(:job) do
      arg(:id, non_null(:id))
      resolve(&R.CMS.job/3)
    end

    @desc "get paged jobs"
    field :paged_jobs, :paged_jobs do
      arg(:filter, non_null(:paged_article_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_jobs/3)
    end

    field :favorite_users, :paged_users do
      arg(:id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:action, :favorite_action, default_value: :favorite)
      arg(:filter, :paged_article_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.reaction_users/3)
    end

    # get all tags
    field :paged_tags, :paged_tags do
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.get_tags/3)
    end

    # TODO: remove
    field :tags, :paged_tags do
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      # TODO: should be passport
      resolve(&R.CMS.get_tags/3)
    end

    # partial
    @desc "get paged tags belongs to community_id or community"
    field :partial_tags, list_of(:tag) do
      arg(:community_id, :id)
      arg(:community, :string)
      arg(:thread, :cms_thread, default_value: :post)

      resolve(&R.CMS.get_tags/3)
    end

    @desc "get paged comments"
    field :paged_comments, :paged_comments do
      arg(:id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:filter, :comments_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_comments/3)
    end

    # comments
    field :comments, :paged_comments do
      arg(:id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:filter, :comments_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_comments/3)
    end
  end
end
