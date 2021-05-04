defmodule GroupherServer.Test.ArticleCollect do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.{Post, Job}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})
    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 community post_attrs job_attrs)a}
  end

  describe "[cms post collect]" do
    @tag :wip2
    test "post can be collect && collects_count should inc by 1",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, article_collect} = CMS.collect_article(:post, post.id, user)
      {:ok, article} = ORM.find(Post, article_collect.post_id)

      assert article.id == post.id
      assert article.collects_count == 1

      {:ok, article_collect} = CMS.collect_article(:post, post.id, user2)
      {:ok, article} = ORM.find(Post, article_collect.post_id)

      assert article.collects_count == 2
    end

    @tag :wip2
    test "post can be undo collect && collects_count should dec by 1",
         ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, article_collect} = CMS.collect_article(:post, post.id, user)
      {:ok, article} = ORM.find(Post, article_collect.post_id)
      assert article.id == post.id
      assert article.collects_count == 1

      {:ok, article_collect} = CMS.undo_collect_article(:post, post.id, user)
      {:ok, article} = ORM.find(Post, article_collect.post_id)
      assert article.collects_count == 0
    end

    @tag :wip
    test "can get collect_users", ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, _article} = CMS.collect_article(:post, post.id, user)
      {:ok, _article} = CMS.collect_article(:post, post.id, user2)

      {:ok, users} = CMS.collected_users(:post, post.id, %{page: 1, size: 2})

      assert users |> is_valid_pagination?(:raw)
      assert user_exist_in?(user, users.entries)
      assert user_exist_in?(user2, users.entries)
    end
  end

  describe "[cms job collect]" do
    @tag :wip2
    test "job can be collect && collects_count should inc by 1",
         ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, article_collect} = CMS.collect_article(:job, job.id, user)
      {:ok, article} = ORM.find(Job, article_collect.job_id)

      assert article.id == job.id
      assert article.collects_count == 1

      {:ok, article_collect} = CMS.collect_article(:job, job.id, user2)
      {:ok, article} = ORM.find(Job, article_collect.job_id)
      assert article.collects_count == 2
    end

    @tag :wip2
    test "job can be undo collect && collects_count should dec by 1",
         ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, article_collect} = CMS.collect_article(:job, job.id, user)
      {:ok, article} = ORM.find(Job, article_collect.job_id)

      assert article.id == job.id
      assert article.collects_count == 1

      {:ok, article_collect} = CMS.undo_collect_article(:job, job.id, user)
      {:ok, article} = ORM.find(Job, article_collect.job_id)
      assert article.collects_count == 0
    end

    @tag :wip2
    test "can get collect_users", ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, _article} = CMS.collect_article(:job, job.id, user)
      {:ok, _article} = CMS.collect_article(:job, job.id, user2)

      {:ok, users} = CMS.collected_users(:job, job.id, %{page: 1, size: 2})

      assert users |> is_valid_pagination?(:raw)
      assert user_exist_in?(user, users.entries)
      assert user_exist_in?(user2, users.entries)
    end
  end
end
