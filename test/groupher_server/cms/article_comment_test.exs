defmodule GroupherServer.Test.CMS.ArticleComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{ArticleComment, ArticleCommentReply, Post, Job}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user user2 post job)a}
  end

  describe "[basic article comment]" do
    @tag :wip
    test "post, job are supported by article comment.", ~m(user post job)a do
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

  describe "[article comment participator]" do
    @tag :wip
    test "post will have participator after comment created", ~m(user post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.write_comment(:post, post.id, post_comment_1, user)

      {:ok, post} = ORM.find(Post, post.id)

      participator = List.first(post.comment_participators)
      assert participator.id == user.id
    end

    @tag :wip
    test "psot participator will not contains same user", ~m(user post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.write_comment(:post, post.id, post_comment_1, user)
      {:ok, _} = CMS.write_comment(:post, post.id, post_comment_1, user)

      {:ok, post} = ORM.find(Post, post.id)

      assert 1 == length(post.comment_participators)
    end

    @tag :wip
    test "recent comment user should appear at first of the psot participators",
         ~m(user user2 post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.write_comment(:post, post.id, post_comment_1, user)
      {:ok, _} = CMS.write_comment(:post, post.id, post_comment_1, user2)

      {:ok, post} = ORM.find(Post, post.id)

      participator = List.first(post.comment_participators)

      assert participator.id == user2.id
    end
  end

  describe "[article comment upvotes]" do
    @tag :wip
    test "user can upvote a post comment", ~m(user post)a do
      comment = "post_comment"
      {:ok, comment} = CMS.write_comment(:post, post.id, comment, user)

      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    @tag :wip
    test "user can upvote a job comment", ~m(user job)a do
      comment = "job_comment"
      {:ok, comment} = CMS.write_comment(:job, job.id, comment, user)

      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    @tag :wip
    test "user upvote a already-upvoted comment fails", ~m(user post)a do
      comment = "post_comment"
      {:ok, comment} = CMS.write_comment(:post, post.id, comment, user)

      CMS.upvote_comment(comment.id, user)
      {:error, _} = CMS.upvote_comment(comment.id, user)
    end
  end

  @tag :wip
  test "paged article comments", ~m(user post)a do
    total_count = 30
    page_number = 1
    page_size = 10

    Enum.reduce(1..total_count, [], fn _, acc ->
      {:ok, value} = CMS.write_comment(:post, post.id, "commment", user)

      acc ++ [value]
    end)

    {:ok, paged_comments} =
      CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size})

    assert page_number == paged_comments.page_number
    assert page_size == paged_comments.page_size
    assert total_count == paged_comments.total_count
  end

  describe "[basic article comment replies]" do
    @tag :wip
    test "exsit comment can be reply", ~m(post user user2)a do
      parent_content = "parent comment"
      reply_content = "reply comment"

      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)
      {:ok, replyed_comment} = CMS.reply_article_comment(parent_comment.id, reply_content, user2)
      assert replyed_comment.reply_to.id == parent_comment.id

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      assert exist_in?(replyed_comment, parent_comment.replies)
    end

    @tag :wip
    test "multi reply should belong to one parent comment", ~m(post user user2)a do
      parent_content = "parent comment"
      reply_content_1 = "reply comment 1"
      reply_content_2 = "reply comment 2"

      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)

      {:ok, replyed_comment_1} =
        CMS.reply_article_comment(parent_comment.id, reply_content_1, user2)

      {:ok, replyed_comment_2} =
        CMS.reply_article_comment(parent_comment.id, reply_content_2, user2)

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      assert exist_in?(replyed_comment_1, parent_comment.replies)
      assert exist_in?(replyed_comment_2, parent_comment.replies)
    end

    @tag :wip2
    test "reply to reply inside a comment should belong same parent comment",
         ~m(post user user2)a do
      parent_content = "parent comment"
      reply_content_1 = "reply comment 1"
      reply_content_2 = "reply comment 2"

      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)

      {:ok, replyed_comment_1} =
        CMS.reply_article_comment(parent_comment.id, reply_content_1, user2)

      {:ok, replyed_comment_2} =
        CMS.reply_article_comment(replyed_comment_1.id, reply_content_2, user2)

      IO.inspect(replyed_comment_2, label: "replyed_comment_2")

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      IO.inspect(parent_comment, label: "parent_comment")

      assert exist_in?(replyed_comment_1, parent_comment.replies)
      assert exist_in?(replyed_comment_2, parent_comment.replies)
    end

    # test "comment replies only contains @max_replies_count replies" do

    # end
  end
end
