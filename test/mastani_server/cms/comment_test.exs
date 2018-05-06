defmodule MastaniServer.Test.CommentTest do
  # currently only test comments for post type, rename and seprherate later
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Test.AssertHelper
  import MastaniServer.Factory
  import ShortMaps

  alias MastaniServer.{CMS, Accounts}
  alias Helper.ORM

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)

    content = "this is a test comment"

    {:ok, comment} =
      CMS.create_comment(:post, :comment, post.id, %Accounts.User{id: user.id}, content)

    {:ok, ~m(post user comment)a}
  end

  describe "[comment CURD]" do
    test "login user comment to exsiting post", ~m(post user)a do
      content = "this is a test comment"

      assert {:ok, comment} =
               CMS.create_comment(:post, :comment, post.id, %Accounts.User{id: user.id}, content)

      assert comment.post_id == post.id
      assert comment.body == content
      assert comment.author_id == user.id
    end

    test "create comment to non-exsit post fails", ~m(user)a do
      content = "this is a test comment"

      assert {:error, _} =
               CMS.create_comment(
                 :post,
                 :comment,
                 non_exsit_id(),
                 %Accounts.User{id: user.id},
                 content
               )
    end

    test "can reply a comment, and reply should be in comment replies list", ~m(comment user)a do
      reply_content = "this is a reply comment"

      {:ok, reply} =
        CMS.reply_comment(:post, comment.id, %Accounts.User{id: user.id}, reply_content)

      {:ok, reply_preload} = ORM.find(CMS.PostComment, reply.id, preload: :reply_to)
      {:ok, comment_preload} = ORM.find(CMS.PostComment, comment.id, preload: :replies)

      assert reply_preload.reply_to.id == comment.id
      assert reply_preload.author_id == user.id
      assert reply_preload.body == reply_content
      # reply id should be in comments replies list
      assert comment_preload.replies |> Enum.any?(&(&1.reply_id == reply.id))
    end

    test "comment can be deleted", ~m(post user)a do
      content = "this is a test comment"

      assert {:ok, comment} =
               CMS.create_comment(:post, :comment, post.id, %Accounts.User{id: user.id}, content)

      {:ok, deleted} = CMS.delete_comment(:post, comment.id)
      assert deleted.id == comment.id
      # IO.inspect hello, label: "hello"
    end

    @tag :wip
    test "after delete, the coments of id > deleted.id should decrease the floor number",
         ~m(post user)a do
      content = "this is a test comment"
      # in setup we have a comment
      total = 30 + 1

      comments =
        Enum.reduce(1..total, [], fn _, acc ->
          {:ok, value} =
            CMS.create_comment(:post, :comment, post.id, %Accounts.User{id: user.id}, content)

          acc ++ [value]
        end)

      [comment_1, comment_2, comment_3, comment_last] = comments |> firstn_and_last(3)

      assert comment_1.floor == 2
      assert comment_2.floor == 3
      assert comment_3.floor == 4
      assert comment_last.floor == total + 1

      {:ok, _} = CMS.delete_comment(:post, comment_1.id)

      {:ok, new_comment_2} = ORM.find(CMS.PostComment, comment_2.id)
      {:ok, new_comment_3} = ORM.find(CMS.PostComment, comment_3.id)
      {:ok, new_comment_last} = ORM.find(CMS.PostComment, comment_last.id)

      assert new_comment_2.floor == 2
      assert new_comment_3.floor == 3
      assert new_comment_last.floor == total
    end

    test "comment with replies should be deleted together", ~m(comment user)a do
      reply_content = "this is a reply comment"

      {:ok, reply} =
        CMS.reply_comment(:post, comment.id, %Accounts.User{id: user.id}, reply_content)

      CMS.PostComment |> ORM.find_delete(comment.id)

      {:error, _} = ORM.find(CMS.PostComment, comment.id)
      {:error, _} = ORM.find(CMS.PostComment, reply.id)

      {:error, _} =
        CMS.PostCommentReply |> ORM.find_by(post_comment_id: comment.id, reply_id: reply.id)
    end

    test "comments pagination should work", ~m(post user)a do
      content = "fake comment"

      Enum.reduce(1..30, [], fn _, acc ->
        {:ok, value} =
          CMS.create_comment(:post, :comment, post.id, %Accounts.User{id: user.id}, content)

        acc ++ [value]
      end)

      {:ok, results} = CMS.list_comments(:post, post.id, %{page: 1, size: 10})

      assert results |> is_valid_pagination?(:raw)
    end

    test "comment reply can be list one-by-one --> by replied user", ~m(comment)a do
      {:ok, user1} = db_insert(:user)
      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)

      {:ok, _} =
        CMS.reply_comment(:post, comment.id, %Accounts.User{id: user1.id}, "reply by user1")

      {:ok, _} =
        CMS.reply_comment(:post, comment.id, %Accounts.User{id: user2.id}, "reply by user2")

      {:ok, _} =
        CMS.reply_comment(:post, comment.id, %Accounts.User{id: user3.id}, "reply by user3")

      {:ok, found_reply1} = CMS.list_replies(:post, comment.id, %Accounts.User{id: user1.id})
      assert user1.id == found_reply1 |> List.first() |> Map.get(:author_id)

      {:ok, found_reply2} = CMS.list_replies(:post, comment.id, %Accounts.User{id: user2.id})
      assert user2.id == found_reply2 |> List.first() |> Map.get(:author_id)

      {:ok, found_reply3} = CMS.list_replies(:post, comment.id, %Accounts.User{id: user3.id})
      assert user3.id == found_reply3 |> List.first() |> Map.get(:author_id)
    end
  end

  describe "[comment Reactions]" do
    test "user can like a comment", ~m(comment user)a do
      # {:ok, like} = CMS.reaction(:post_comment, :like, comment.id, user.id)
      {:ok, like} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user.id})
      {:ok, comment_preload} = ORM.find(CMS.PostComment, comment.id, preload: :likes)

      assert comment_preload.likes |> Enum.any?(&(&1.id == like.id))
    end

    test "user like comment twice fails", ~m(comment user)a do
      {:ok, _} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user.id})
      {:error, _error} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user.id})
      # TODO: fix err_msg later
      # IO.inspect error, label: "hello"
    end

    test "user can undo a like action", ~m(comment user)a do
      {:ok, like} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user.id})
      {:ok, _} = CMS.undo_like_comment(:post_comment, comment.id, %Accounts.User{id: user.id})

      {:ok, comment_preload} = ORM.find(CMS.PostComment, comment.id, preload: :likes)
      assert false == comment_preload.likes |> Enum.any?(&(&1.id == like.id))
    end

    test "user can dislike a comment", ~m(comment user)a do
      # {:ok, like} = CMS.reaction(:post_comment, :like, comment.id, user.id)
      {:ok, dislike} = CMS.dislike_comment(:post_comment, comment.id, %Accounts.User{id: user.id})
      {:ok, comment_preload} = ORM.find(CMS.PostComment, comment.id, preload: :dislikes)

      assert comment_preload.dislikes |> Enum.any?(&(&1.id == dislike.id))
    end

    test "user can undo a dislike action", ~m(comment user)a do
      {:ok, dislike} = CMS.dislike_comment(:post_comment, comment.id, %Accounts.User{id: user.id})
      {:ok, _} = CMS.undo_dislike_comment(:post_comment, comment.id, %Accounts.User{id: user.id})

      {:ok, comment_preload} = ORM.find(CMS.PostComment, comment.id, preload: :dislikes)
      assert false == comment_preload.dislikes |> Enum.any?(&(&1.id == dislike.id))
    end

    test "user can get paged likes of a post comment", ~m(comment)a do
      {:ok, user1} = db_insert(:user)
      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)

      {:ok, _like1} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user1.id})
      {:ok, _like2} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user2.id})
      {:ok, _like3} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user3.id})

      {:ok, results} = CMS.reaction_users(:post_comment, :like, comment.id, %{page: 1, size: 10})

      assert results.entries |> Enum.any?(&(&1.id == user1.id))
      assert results.entries |> Enum.any?(&(&1.id == user2.id))
      assert results.entries |> Enum.any?(&(&1.id == user3.id))
    end
  end
end
