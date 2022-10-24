defmodule GroupherServer.Test.Seeds.Articles do
  @moduledoc false
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.Model.User
  alias GroupherServer.CMS

  alias CMS.Model.{Post, Job, Radar, Blog, Works}
  # alias CMS.Delegate.SeedsConfig

  alias Helper.ORM

  describe "[posts seed]" do
    test "can seed posts" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :post, 5)

      {:ok, posts} = ORM.find_all(Post, %{page: 1, size: 20})
      ramdom_post = posts.entries |> List.first()

      {:ok, ramdom_post} = ORM.find(Post, ramdom_post.id, preload: [:article_tags, :document])

      assert ramdom_post.article_tags |> length == 1
      assert ramdom_post.upvotes_count !== 0
      assert ramdom_post.meta.latest_upvoted_users |> length !== 0
      assert not is_nil(ramdom_post.document.body_html)

      original_community_ids =
        posts.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]

      {:ok, paged_comments} =
        CMS.paged_comments(:post, ramdom_post.id, %{page: 1, size: 10}, :timeline)

      # IO.inspect(paged_comments, label: "paged_comments -> ")
      assert paged_comments.total_count !== 0
    end

    test "can seed jobs" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :job, 5)

      {:ok, jobs} = ORM.find_all(Job, %{page: 1, size: 20})
      ramdom_job = jobs.entries |> List.first()
      {:ok, ramdom_job} = ORM.find(Job, ramdom_job.id, preload: :article_tags)
      assert ramdom_job.article_tags |> length == 3
      assert ramdom_job.upvotes_count !== 0
      assert ramdom_job.meta.latest_upvoted_users |> length !== 0

      original_community_ids = jobs.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]

      {:ok, paged_comments} =
        CMS.paged_comments(:job, ramdom_job.id, %{page: 1, size: 20}, :timeline)

      assert paged_comments.total_count !== 0
    end

    test "can seed radars" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :radar, 5)

      {:ok, radars} = ORM.find_all(Radar, %{page: 1, size: 20})
      ramdom_radar = radars.entries |> List.first()
      {:ok, ramdom_radar} = ORM.find(Radar, ramdom_radar.id, preload: [:article_tags])

      assert ramdom_radar.upvotes_count !== 0
      assert ramdom_radar.meta.latest_upvoted_users |> length !== 0

      original_community_ids =
        radars.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]

      {:ok, paged_comments} =
        CMS.paged_comments(:radar, ramdom_radar.id, %{page: 1, size: 20}, :timeline)

      assert paged_comments.total_count !== 0
    end

    # test "can seed blogs" do
    #   {:ok, community} = CMS.seed_community(:home)
    #   CMS.seed_articles(community, :blog, 5)

    #   {:ok, blogs} = ORM.find_all(Blog, %{page: 1, size: 20})
    #   ramdom_blog = blogs.entries |> List.first()
    #   {:ok, ramdom_blog} = ORM.find(Blog, ramdom_blog.id, preload: [:article_tags])
    #   assert ramdom_blog.upvotes_count !== 0
    #   assert ramdom_blog.meta.latest_upvoted_users |> length !== 0

    #   original_community_ids =
    #     blogs.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

    #   assert original_community_ids === [community.id]

    #   {:ok, paged_comments} =
    #     CMS.paged_comments(:blog, ramdom_blog.id, %{page: 1, size: 20}, :timeline)

    #   assert paged_comments.total_count !== 0
    # end

    # test "can seed works" do
    #   {:ok, community} = CMS.seed_community(:home)
    #   CMS.seed_articles(community, :works, 5)

    #   {:ok, works} = ORM.find_all(Works, %{page: 1, size: 20})
    #   ramdom_works = works.entries |> List.first()
    #   {:ok, ramdom_works} = ORM.find(Works, ramdom_works.id, preload: [:article_tags])

    #   assert ramdom_works.upvotes_count !== 0
    #   assert ramdom_works.meta.latest_upvoted_users |> length !== 0

    #   original_community_ids =
    #     works.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

    #   assert original_community_ids === [community.id]

    #   {:ok, paged_comments} =
    #     CMS.paged_comments(:works, ramdom_works.id, %{page: 1, size: 20}, :timeline)

    #   assert paged_comments.total_count !== 0
    # end
  end
end
