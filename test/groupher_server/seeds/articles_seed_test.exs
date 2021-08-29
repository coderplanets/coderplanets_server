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
      {:ok, ramdom_post} = ORM.find(Post, ramdom_post.id, preload: :article_tags)
      assert ramdom_post.article_tags |> length == 1

      original_community_ids =
        posts.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]
    end

    test "can seed jobs" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :job, 5)

      {:ok, jobs} = ORM.find_all(Job, %{page: 1, size: 20})
      ramdom_job = jobs.entries |> List.first()
      {:ok, ramdom_job} = ORM.find(Job, ramdom_job.id, preload: :article_tags)
      assert ramdom_job.article_tags |> length == 3

      original_community_ids = jobs.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]
    end

    test "can seed radars" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :radar, 5)

      {:ok, radars} = ORM.find_all(Radar, %{page: 1, size: 20})

      original_community_ids =
        radars.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]
    end

    test "can seed blogs" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :blog, 5)

      {:ok, blogs} = ORM.find_all(Blog, %{page: 1, size: 20})

      original_community_ids =
        blogs.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]
    end

    test "can seed works" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :works, 5)

      {:ok, works} = ORM.find_all(Works, %{page: 1, size: 20})

      original_community_ids =
        works.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]
    end
  end
end
