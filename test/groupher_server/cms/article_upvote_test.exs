defmodule GroupherServer.Test.ArticleUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})
    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 community post_attrs job_attrs)a}
  end

  describe "[cms post upvote]" do
    @tag :wip
    test "post can be upvote && upvotes_count should inc by 1",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, article} = CMS.upvote_article(:post, post.id, user)
      assert article.id == post.id
      assert article.upvotes_count == 1

      {:ok, article} = CMS.upvote_article(:post, post.id, user2)
      assert article.upvotes_count == 2
    end

    @tag :wip
    test "post can be undo upvote && upvotes_count should dec by 1",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, article} = CMS.upvote_article(:post, post.id, user)
      assert article.id == post.id
      assert article.upvotes_count == 1

      {:ok, article} = CMS.undo_upvote_article(:post, post.id, user2)
      assert article.upvotes_count == 0
    end

    @tag :wip
    test "can get upvotes_users", ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, _article} = CMS.upvote_article(:post, post.id, user)
      {:ok, _article} = CMS.upvote_article(:post, post.id, user2)

      {:ok, users} = CMS.upvoted_users(:post, post.id, %{page: 1, size: 2})

      assert users |> is_valid_pagination?(:raw)
      assert user_exist_in?(user, users.entries)
      assert user_exist_in?(user2, users.entries)
    end
  end

  describe "[cms job upvote]" do
    @tag :wip
    test "job can be upvote && upvotes_count should inc by 1",
         ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, article} = CMS.upvote_article(:job, job.id, user)
      assert article.id == job.id
      assert article.upvotes_count == 1

      {:ok, article} = CMS.upvote_article(:job, job.id, user2)
      assert article.upvotes_count == 2
    end

    @tag :wip
    test "job can be undo upvote && upvotes_count should dec by 1",
         ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, article} = CMS.upvote_article(:job, job.id, user)
      assert article.id == job.id
      assert article.upvotes_count == 1

      {:ok, article} = CMS.undo_upvote_article(:job, job.id, user2)
      assert article.upvotes_count == 0
    end

    @tag :wip
    test "can get upvotes_users", ~m(user user2 community job_attrs)a do
      {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

      {:ok, _article} = CMS.upvote_article(:job, job.id, user)
      {:ok, _article} = CMS.upvote_article(:job, job.id, user2)

      {:ok, users} = CMS.upvoted_users(:job, job.id, %{page: 1, size: 2})

      assert users |> is_valid_pagination?(:raw)
      assert user_exist_in?(user, users.entries)
      assert user_exist_in?(user2, users.entries)
    end
  end
end
