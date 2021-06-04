defmodule GroupherServer.Test.ArticleCollect do
  @moduledoc false
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.{Post, Job}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})
    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 community post_attrs job_attrs)a}
  end

  describe "[cms post collect]" do
    test "post can be collect && collects_count should inc by 1",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, article_collect} = CMS.collect_article(:post, post.id, user)
      {:ok, article} = ORM.find(Post, article_collect.post_id)

      assert article.id == post.id
      assert article.collects_count == 1

      {:ok, article_collect} = CMS.collect_article(:post, post.id, user2)
      {:ok, article} = ORM.find(Post, article_collect.post_id)

      assert article.collects_count == 2
    end

    test "post can be undo collect && collects_count should dec by 1",
         ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, article_collect} = CMS.collect_article(:post, post.id, user)
      {:ok, article} = ORM.find(Post, article_collect.post_id)
      assert article.id == post.id
      assert article.collects_count == 1

      {:ok, article_collect} = CMS.undo_collect_article(:post, post.id, user)
      {:ok, article} = ORM.find(Post, article_collect.post_id)
      assert article.collects_count == 0
    end

    test "can get collect_users", ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, _article} = CMS.collect_article(:post, post.id, user)
      {:ok, _article} = CMS.collect_article(:post, post.id, user2)

      {:ok, users} = CMS.collected_users(:post, post.id, %{page: 1, size: 2})

      assert users |> is_valid_pagination?(:raw)
      assert user_exist_in?(user, users.entries)
      assert user_exist_in?(user2, users.entries)
    end

    test "post meta history should be updated", ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _} = CMS.collect_article(:post, post.id, user)

      {:ok, article} = ORM.find(Post, post.id)
      assert user.id in article.meta.collected_user_ids

      {:ok, _} = CMS.collect_article(:post, post.id, user2)
      {:ok, article} = ORM.find(Post, post.id)

      assert user.id in article.meta.collected_user_ids
      assert user2.id in article.meta.collected_user_ids
    end

    test "post meta history should be updated after undo collect",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _} = CMS.collect_article(:post, post.id, user)
      {:ok, _} = CMS.collect_article(:post, post.id, user2)

      {:ok, article} = ORM.find(Post, post.id)
      assert user.id in article.meta.collected_user_ids
      assert user2.id in article.meta.collected_user_ids

      {:ok, _} = CMS.undo_collect_article(:post, post.id, user2)
      {:ok, article} = ORM.find(Post, post.id)
      assert user2.id not in article.meta.collected_user_ids

      {:ok, _} = CMS.undo_collect_article(:post, post.id, user)
      {:ok, article} = ORM.find(Post, post.id)
      assert user.id not in article.meta.collected_user_ids
      assert user2.id not in article.meta.collected_user_ids
    end
  end

  describe "[cms job collect]" do
    test "job can be collect && collects_count should inc by 1",
         ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, article_collect} = CMS.collect_article(:job, job.id, user)
      {:ok, article} = ORM.find(Job, article_collect.job_id)

      assert article.id == job.id
      assert article.collects_count == 1

      {:ok, article_collect} = CMS.collect_article(:job, job.id, user2)
      {:ok, article} = ORM.find(Job, article_collect.job_id)
      assert article.collects_count == 2
    end

    test "job can be undo collect && collects_count should dec by 1",
         ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, article_collect} = CMS.collect_article(:job, job.id, user)
      {:ok, article} = ORM.find(Job, article_collect.job_id)

      assert article.id == job.id
      assert article.collects_count == 1

      {:ok, article_collect} = CMS.undo_collect_article(:job, job.id, user)
      {:ok, article} = ORM.find(Job, article_collect.job_id)
      assert article.collects_count == 0
    end

    test "can get collect_users", ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, _article} = CMS.collect_article(:job, job.id, user)
      {:ok, _article} = CMS.collect_article(:job, job.id, user2)

      {:ok, users} = CMS.collected_users(:job, job.id, %{page: 1, size: 2})

      assert users |> is_valid_pagination?(:raw)
      assert user_exist_in?(user, users.entries)
      assert user_exist_in?(user2, users.entries)
    end

    test "job meta history should be updated", ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.collect_article(:job, job.id, user)

      {:ok, article} = ORM.find(Job, job.id)
      assert user.id in article.meta.collected_user_ids

      {:ok, _} = CMS.collect_article(:job, job.id, user2)
      {:ok, article} = ORM.find(Job, job.id)
      assert user.id in article.meta.collected_user_ids
      assert user2.id in article.meta.collected_user_ids
    end

    test "job meta history should be updated after undo collect",
         ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.collect_article(:job, job.id, user)
      {:ok, _} = CMS.collect_article(:job, job.id, user2)

      {:ok, article} = ORM.find(Job, job.id)
      assert user.id in article.meta.collected_user_ids
      assert user2.id in article.meta.collected_user_ids

      {:ok, _} = CMS.undo_collect_article(:job, job.id, user2)
      {:ok, article} = ORM.find(Job, job.id)
      assert user2.id not in article.meta.collected_user_ids

      {:ok, _} = CMS.undo_collect_article(:job, job.id, user)
      {:ok, article} = ORM.find(Job, job.id)
      assert user.id not in article.meta.collected_user_ids
      assert user2.id not in article.meta.collected_user_ids
    end
  end
end
