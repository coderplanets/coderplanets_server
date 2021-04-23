defmodule GroupherServerWeb.Schema.CMS.Queries do
  @moduledoc """
  CMS queries
  """
  use Helper.GqlSchemaSuite

  object :cms_queries do
    @desc "spec community info"
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
      arg(:id, :id)
      arg(:community, :string)
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

    @desc "get community geo cities info"
    field :community_geo_info, list_of(:geo_info) do
      arg(:id, non_null(:id))
      arg(:raw, :string)

      resolve(&R.CMS.community_geo_info/3)
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
      arg(:filter, non_null(:paged_posts_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_posts/3)
    end

    @desc "get repo by id"
    field :repo, non_null(:repo) do
      arg(:id, non_null(:id))
      resolve(&R.CMS.repo/3)
    end

    @desc "get paged repos"
    field :paged_repos, :paged_repos do
      arg(:filter, non_null(:paged_repos_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_repos/3)
    end

    @desc "get wiki by community raw name"
    field :wiki, non_null(:wiki) do
      arg(:community, :string)
      resolve(&R.CMS.wiki/3)
    end

    @desc "get cheatsheet by community raw name"
    field :cheatsheet, non_null(:cheatsheet) do
      arg(:community, :string)
      resolve(&R.CMS.cheatsheet/3)
    end

    @desc "get job by id"
    field :job, non_null(:job) do
      arg(:id, non_null(:id))
      resolve(&R.CMS.job/3)
    end

    @desc "get paged jobs"
    field :paged_jobs, :paged_jobs do
      arg(:filter, non_null(:paged_jobs_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_jobs/3)
    end

    @desc "get paged users of a reaction related to cms content"
    field :reaction_users, :paged_users do
      arg(:id, non_null(:id))
      arg(:thread, :react_thread, default_value: :post)
      arg(:action, non_null(:react_action))
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.CMS.reaction_users/3)
    end

    # get all tags
    @desc "get paged tags"
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
      arg(:topic, :string)
      arg(:all, :boolean, default_value: false)

      resolve(&R.CMS.get_tags/3)
    end

    @desc "get paged article comments"
    field :paged_article_comments, :paged_article_comments do
      arg(:id, non_null(:id))
      arg(:mode, :article_comments_mode, default_value: :replies)
      arg(:thread, :cms_thread, default_value: :post)
      arg(:filter, :comments_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_article_comments/3)
    end

    @desc "get paged replies of a comment"
    field :paged_comment_replies, :paged_article_replies do
      arg(:id, non_null(:id))
      arg(:filter, :comments_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_comment_replies/3)
    end

    @desc "get paged comments"
    field :paged_comments, :paged_comments do
      arg(:id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:filter, :comments_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_comments/3)
    end

    @desc "get paged comments participators"
    field :paged_comments_participators, :paged_users do
      arg(:id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:filter, :paged_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_comments_participators/3)
    end

    # comments
    # TODO: remove
    field :comments, :paged_comments do
      arg(:id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)
      arg(:filter, :comments_filter)

      middleware(M.PageSizeProof)
      resolve(&R.CMS.paged_comments/3)
    end

    @desc "search communities by title"
    field :search_communities, :paged_communities do
      arg(:title, non_null(:string))
      arg(:part, :community_type, default_value: :community)

      resolve(&R.CMS.search_items/3)
    end

    @desc "search post by title"
    field :search_posts, :paged_posts do
      arg(:title, non_null(:string))
      arg(:part, :post_thread, default_value: :post)

      resolve(&R.CMS.search_items/3)
    end

    @desc "search job by title"
    field :search_jobs, :paged_jobs do
      arg(:title, non_null(:string))
      arg(:part, :job_thread, default_value: :job)

      resolve(&R.CMS.search_items/3)
    end

    @desc "search repo by title"
    field :search_repos, :paged_repos do
      arg(:title, non_null(:string))
      arg(:part, :repo_thread, default_value: :repo)

      resolve(&R.CMS.search_items/3)
    end
  end
end
