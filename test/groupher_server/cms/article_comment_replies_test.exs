defmodule GroupherServer.Test.CMS.ArticleCommentReplies do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{ArticleComment, ArticleCommentReply, Post, Job}

  @max_replies_count CMS.ArticleComment.max_replies_count()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user user2 post job)a}
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

    @tag :wip
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

      # IO.inspect(replyed_comment_2, label: "replyed_comment_2")

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      assert exist_in?(replyed_comment_1, parent_comment.replies)
      assert exist_in?(replyed_comment_2, parent_comment.replies)

      {:ok, replyed_comment_1} = ORM.find(ArticleComment, replyed_comment_1.id)
      {:ok, replyed_comment_2} = ORM.find(ArticleComment, replyed_comment_2.id)

      assert replyed_comment_1.reply_to_id == parent_comment.id
      assert replyed_comment_2.reply_to_id == replyed_comment_1.id
    end

    @tag :wip
    test "comment replies only contains @max_replies_count replies", ~m(post user)a do
      total_reply_count = @max_replies_count + 1

      {:ok, parent_comment} = CMS.write_comment(:post, post.id, "parent_conent", user)

      reply_comment_list =
        Enum.reduce(1..total_reply_count, [], fn n, acc ->
          {:ok, replyed_comment} =
            CMS.reply_article_comment(parent_comment.id, "reply_content_#{n}", user)

          acc ++ [replyed_comment]
        end)

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      assert length(parent_comment.replies) == @max_replies_count
      assert exist_in?(Enum.at(reply_comment_list, 0), parent_comment.replies)
      assert exist_in?(Enum.at(reply_comment_list, 1), parent_comment.replies)
      assert exist_in?(Enum.at(reply_comment_list, 2), parent_comment.replies)
      assert not exist_in?(List.last(reply_comment_list), parent_comment.replies)
    end

    @tag :wip2
    test "replyed user should appear in article comment participators", ~m(post user user2)a do
      {:ok, parent_comment} = CMS.write_comment(:post, post.id, "parent_conent", user)
      {:ok, _} = CMS.reply_article_comment(parent_comment.id, "reply_content", user2)

      {:ok, article} = ORM.find(Post, post.id)

      assert exist_in?(user, article.comment_participators)
      assert exist_in?(user2, article.comment_participators)
    end

    # test "total replies count for parent comment" do

    # end
  end
end
