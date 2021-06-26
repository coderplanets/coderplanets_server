defmodule GroupherServer.Test.CMS.Comments.DrinkCommentReplies do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Comment, Drink}

  @max_parent_replies_count Comment.max_parent_replies_count()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, drink} = db_insert(:drink)

    {:ok, ~m(user user2 drink)a}
  end

  describe "[basic article comment replies]" do
    test "exsit comment can be reply", ~m(drink user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)
      {:ok, replyed_comment} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)
      assert replyed_comment.reply_to.id == parent_comment.id

      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)

      assert exist_in?(replyed_comment, parent_comment.replies)
    end

    test "deleted comment can not be reply", ~m(drink user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)
      {:ok, _} = CMS.delete_comment(parent_comment)

      {:error, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)
    end

    test "multi reply should belong to one parent comment", ~m(drink user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)

      {:ok, replyed_comment_1} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)

      {:ok, replyed_comment_2} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)

      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)

      assert exist_in?(replyed_comment_1, parent_comment.replies)
      assert exist_in?(replyed_comment_2, parent_comment.replies)
    end

    test "reply to reply inside a comment should belong same parent comment",
         ~m(drink user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)

      {:ok, replyed_comment_1} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)

      {:ok, replyed_comment_2} = CMS.reply_comment(replyed_comment_1.id, mock_comment(), user2)

      {:ok, replyed_comment_3} = CMS.reply_comment(replyed_comment_2.id, mock_comment(), user)

      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)

      # IO.inspect(parent_comment.replies, label: "parent_comment.replies")

      assert exist_in?(replyed_comment_1, parent_comment.replies)
      assert exist_in?(replyed_comment_2, parent_comment.replies)
      assert exist_in?(replyed_comment_3, parent_comment.replies)

      {:ok, replyed_comment_1} = ORM.find(Comment, replyed_comment_1.id)
      {:ok, replyed_comment_2} = ORM.find(Comment, replyed_comment_2.id)
      {:ok, replyed_comment_3} = ORM.find(Comment, replyed_comment_3.id)

      assert replyed_comment_1.reply_to_id == parent_comment.id
      assert replyed_comment_2.reply_to_id == replyed_comment_1.id
      assert replyed_comment_3.reply_to_id == replyed_comment_2.id
    end

    test "reply to reply inside a comment should have is_reply_to_others flag in meta",
         ~m(drink user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)

      {:ok, replyed_comment_1} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)

      {:ok, replyed_comment_2} = CMS.reply_comment(replyed_comment_1.id, mock_comment(), user2)

      {:ok, replyed_comment_3} = CMS.reply_comment(replyed_comment_2.id, mock_comment(), user)

      {:ok, _parent_comment} = ORM.find(Comment, parent_comment.id)

      {:ok, replyed_comment_1} = ORM.find(Comment, replyed_comment_1.id)
      {:ok, replyed_comment_2} = ORM.find(Comment, replyed_comment_2.id)
      {:ok, replyed_comment_3} = ORM.find(Comment, replyed_comment_3.id)

      assert not replyed_comment_1.meta.is_reply_to_others
      assert replyed_comment_2.meta.is_reply_to_others
      assert replyed_comment_3.meta.is_reply_to_others
    end

    test "comment replies only contains @max_parent_replies_count replies", ~m(drink user)a do
      total_reply_count = @max_parent_replies_count + 1

      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)

      reply_comment_list =
        Enum.reduce(1..total_reply_count, [], fn n, acc ->
          {:ok, replyed_comment} =
            CMS.reply_comment(parent_comment.id, mock_comment("reply_content_#{n}"), user)

          acc ++ [replyed_comment]
        end)

      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)

      assert length(parent_comment.replies) == @max_parent_replies_count
      assert exist_in?(Enum.at(reply_comment_list, 0), parent_comment.replies)
      assert exist_in?(Enum.at(reply_comment_list, 1), parent_comment.replies)
      assert exist_in?(Enum.at(reply_comment_list, 2), parent_comment.replies)
      assert not exist_in?(List.last(reply_comment_list), parent_comment.replies)
    end

    test "replyed user should appear in article comment participants", ~m(drink user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)
      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)

      {:ok, article} = ORM.find(Drink, drink.id)

      assert exist_in?(user, article.comments_participants)
      assert exist_in?(user2, article.comments_participants)
    end

    test "replies count should inc by 1 after got replyed", ~m(drink user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)
      assert parent_comment.replies_count === 0

      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)
      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)
      assert parent_comment.replies_count === 1

      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user2)
      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)
      assert parent_comment.replies_count === 2
    end
  end

  describe "[paged article comment replies]" do
    test "can get paged replies of a parent comment", ~m(drink user)a do
      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)
      {:ok, paged_replies} = CMS.paged_comment_replies(parent_comment.id, %{page: 1, size: 20})
      assert is_valid_pagination?(paged_replies, :raw, :empty)

      total_reply_count = 30

      reply_comment_list =
        Enum.reduce(1..total_reply_count, [], fn n, acc ->
          {:ok, replyed_comment} =
            CMS.reply_comment(parent_comment.id, mock_comment("reply_content_#{n}"), user)

          acc ++ [replyed_comment]
        end)

      {:ok, paged_replies} = CMS.paged_comment_replies(parent_comment.id, %{page: 1, size: 20})

      assert total_reply_count == paged_replies.total_count
      assert is_valid_pagination?(paged_replies, :raw)

      assert exist_in?(Enum.at(reply_comment_list, 0), paged_replies.entries)
      assert exist_in?(Enum.at(reply_comment_list, 1), paged_replies.entries)
      assert exist_in?(Enum.at(reply_comment_list, 2), paged_replies.entries)
      assert exist_in?(Enum.at(reply_comment_list, 3), paged_replies.entries)
    end

    test "can get reply_to info of a parent comment", ~m(drink user)a do
      page_number = 1
      page_size = 10

      {:ok, parent_comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)

      {:ok, reply_comment} = CMS.reply_comment(parent_comment.id, mock_comment(), user)

      {:ok, reply_comment2} = CMS.reply_comment(parent_comment.id, mock_comment(), user)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :drink,
          drink.id,
          %{page: page_number, size: page_size},
          :timeline
        )

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
