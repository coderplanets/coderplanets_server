defmodule GroupherServer.Test.CMS.ArticleComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{ArticleComment, Post, Job}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user post job)a}
  end

  describe "[basic article comment]" do
    @tag :wip2
    test "post, job are supported by article comment", ~m(user post job)a do
      post_comment_1 = "post_comment 1"
      post_comment_2 = "post_comment 2"
      job_comment_1 = "job_comment 1"
      job_comment_2 = "job_comment 2"

      {:ok, _} = CMS.write_comment(:post, post.id, post_comment_1, user)
      {:ok, _} = CMS.write_comment(:post, post.id, post_comment_2, user)

      {:ok, _} = CMS.write_comment(:job, job.id, job_comment_1, user)
      {:ok, _} = CMS.write_comment(:job, job.id, job_comment_2, user)

      {:ok, post} = ORM.find(Post, post.id, preload: :article_comments)
      {:ok, job} = ORM.find(Job, job.id, preload: :article_comments)

      assert List.first(post.article_comments).body_html == post_comment_1
      assert List.first(job.article_comments).body_html == job_comment_1
    end
  end

  describe "[article comment upvotes]" do
    @tag :wip2
    test "user can upvote a post comment", ~m(user post)a do
      comment = "post_comment"
      {:ok, comment} = CMS.write_comment(:post, post.id, comment, user)

      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    @tag :wip2
    test "user can upvote a job comment", ~m(user job)a do
      comment = "job_comment"
      {:ok, comment} = CMS.write_comment(:job, job.id, comment, user)

      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    @tag :wip2
    test "user upvote a already-upvoted comment fails", ~m(user post)a do
      comment = "post_comment"
      {:ok, comment} = CMS.write_comment(:post, post.id, comment, user)

      CMS.upvote_comment(comment.id, user)
      {:error, _} = CMS.upvote_comment(comment.id, user)
    end
  end
end
