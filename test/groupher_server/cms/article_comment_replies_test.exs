defmodule GroupherServer.Test.CMS.ArticleCommentReplies do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{ArticleComment, Post}

  @max_parent_replies_count CMS.ArticleComment.max_parent_replies_count()

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

      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)
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

      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)

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

      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)

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
    test "comment replies only contains @max_parent_replies_count replies", ~m(post user)a do
      total_reply_count = @max_parent_replies_count + 1

      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, "parent_conent", user)

      reply_comment_list =
        Enum.reduce(1..total_reply_count, [], fn n, acc ->
          {:ok, replyed_comment} =
            CMS.reply_article_comment(parent_comment.id, "reply_content_#{n}", user)

          acc ++ [replyed_comment]
        end)

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      assert length(parent_comment.replies) == @max_parent_replies_count
      assert exist_in?(Enum.at(reply_comment_list, 0), parent_comment.replies)
      assert exist_in?(Enum.at(reply_comment_list, 1), parent_comment.replies)
      assert exist_in?(Enum.at(reply_comment_list, 2), parent_comment.replies)
      assert not exist_in?(List.last(reply_comment_list), parent_comment.replies)
    end

    @tag :wip
    test "replyed user should appear in article comment participators", ~m(post user user2)a do
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, "parent_conent", user)
      {:ok, _} = CMS.reply_article_comment(parent_comment.id, "reply_content", user2)

      {:ok, article} = ORM.find(Post, post.id)

      assert exist_in?(user, article.comment_participators)
      assert exist_in?(user2, article.comment_participators)
    end

    @tag :wip
    test "replies count should inc by 1 after got replyed", ~m(post user user2)a do
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, "parent_conent", user)
      assert parent_comment.replies_count === 0

      {:ok, _} = CMS.reply_article_comment(parent_comment.id, "reply_content", user2)
      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)
      assert parent_comment.replies_count === 1

      {:ok, _} = CMS.reply_article_comment(parent_comment.id, "reply_content", user2)
      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)
      assert parent_comment.replies_count === 2
    end
  end

  describe "[paged article comment replies]" do
    @tag :wip
    test "can get paged replies of a parent comment", ~m(post user)a do
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, "parent_conent", user)
      {:ok, paged_replies} = CMS.list_comment_replies(parent_comment.id, %{page: 1, size: 20})
      assert is_valid_pagination?(paged_replies, :raw, :empty)

      total_reply_count = 30

      reply_comment_list =
        Enum.reduce(1..total_reply_count, [], fn n, acc ->
          {:ok, replyed_comment} =
            CMS.reply_article_comment(parent_comment.id, "reply_content_#{n}", user)

          acc ++ [replyed_comment]
        end)

      {:ok, paged_replies} = CMS.list_comment_replies(parent_comment.id, %{page: 1, size: 20})

      assert total_reply_count == paged_replies.total_count
      assert is_valid_pagination?(paged_replies, :raw)

      assert exist_in?(Enum.at(reply_comment_list, 0), paged_replies.entries)
      assert exist_in?(Enum.at(reply_comment_list, 1), paged_replies.entries)
      assert exist_in?(Enum.at(reply_comment_list, 2), paged_replies.entries)
      assert exist_in?(Enum.at(reply_comment_list, 3), paged_replies.entries)
    end

    @tag :wip
    test "can get reply_to info of a parent comment", ~m(post user)a do
      page_number = 1
      page_size = 10

      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, "parent_conent", user)

      {:ok, reply_comment} = CMS.reply_article_comment(parent_comment.id, "reply_content_1", user)

      {:ok, reply_comment2} =
        CMS.reply_article_comment(parent_comment.id, "reply_content_2", user)

      {:ok, paged_comments} =
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size})

      reply_comment = Enum.find(paged_comments.entries, &(&1.id == reply_comment.id))

      assert reply_comment.reply_to.id == parent_comment.id
      assert reply_comment.reply_to.body_html == parent_comment.body_html
      assert reply_comment.reply_to.author.id == parent_comment.author_id

      reply_comment2 = Enum.find(paged_comments.entries, &(&1.id == reply_comment2.id))

      assert reply_comment2.reply_to.id == parent_comment.id
      assert reply_comment2.reply_to.body_html == parent_comment.body_html
      assert reply_comment2.reply_to.author.id == parent_comment.author_id
    end
  end
end
