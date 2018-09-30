defmodule MastaniServer.Test.VideoComment do
  # currently only test comments for video type, rename and seprherate later
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.CMS

  alias CMS.{VideoComment, VideoCommentReply}

  setup do
    {:ok, video} = db_insert(:video)
    {:ok, user} = db_insert(:user)

    body = "this is a test comment"

    {:ok, comment} = CMS.create_comment(:video, video.id, body, user)

    {:ok, ~m(video user comment)a}
  end

  describe "[comment CURD]" do
    test "login user comment to exsiting video", ~m(video user)a do
      body = "this is a test comment"

      assert {:ok, comment} = CMS.create_comment(:video, video.id, body, user)

      assert comment.video_id == video.id
      assert comment.body == body
      assert comment.author_id == user.id
    end

    test "created comment should have a increased floor number", ~m(video user)a do
      body = "this is a test comment"

      assert {:ok, comment1} = CMS.create_comment(:video, video.id, body, user)

      {:ok, user2} = db_insert(:user)

      assert {:ok, comment2} = CMS.create_comment(:video, video.id, body, user2)

      assert comment1.floor == 2
      assert comment2.floor == 3
    end

    test "create comment to non-exsit video fails", ~m(user)a do
      body = "this is a test comment"

      assert {:error, _} = CMS.create_comment(:video, non_exsit_id(), body, user)
    end

    test "can reply a comment, and reply should be in comment replies list", ~m(comment user)a do
      reply_body = "this is a reply comment"

      {:ok, reply} = CMS.reply_comment(:video, comment.id, reply_body, user)

      {:ok, reply_preload} = ORM.find(VideoComment, reply.id, preload: :reply_to)
      {:ok, comment_preload} = ORM.find(VideoComment, comment.id, preload: :replies)

      assert reply_preload.reply_to.id == comment.id
      assert reply_preload.author_id == user.id
      assert reply_preload.body == reply_body
      # reply id should be in comments replies list
      assert comment_preload.replies |> Enum.any?(&(&1.reply_id == reply.id))
    end

    test "comment can be deleted", ~m(video user)a do
      body = "this is a test comment"

      assert {:ok, comment} = CMS.create_comment(:video, video.id, body, user)

      {:ok, deleted} = CMS.delete_comment(:video, comment.id)
      assert deleted.id == comment.id
    end

    # TODO  it's bug
    test "after delete, the coments of id > deleted.id should decrease the floor number",
         ~m(video user)a do
      body = "this is a test comment"
      # in setup we have a comment
      total = 30 + 1

      comments =
        Enum.reduce(1..total, [], fn _, acc ->
          {:ok, value} = CMS.create_comment(:video, video.id, body, user)

          acc ++ [value]
        end)

      [comment_1, comment_2, comment_3, comment_last] = comments |> firstn_and_last(3)

      assert comment_1.floor == 2
      assert comment_2.floor == 3
      assert comment_3.floor == 4
      assert comment_last.floor == total + 1

      {:ok, _} = CMS.delete_comment(:video, comment_1.id)

      {:ok, new_comment_2} = ORM.find(VideoComment, comment_2.id)
      {:ok, new_comment_3} = ORM.find(VideoComment, comment_3.id)
      {:ok, new_comment_last} = ORM.find(VideoComment, comment_last.id)

      assert new_comment_2.floor == 2
      assert new_comment_3.floor == 3
      assert new_comment_last.floor == total
    end

    test "comment with replies should be deleted together", ~m(comment user)a do
      reply_body = "this is a reply comment"

      {:ok, reply} = CMS.reply_comment(:video, comment.id, reply_body, user)

      VideoComment |> ORM.find_delete(comment.id)

      {:error, _} = ORM.find(VideoComment, comment.id)
      {:error, _} = ORM.find(VideoComment, reply.id)

      {:error, _} =
        VideoCommentReply |> ORM.find_by(video_comment_id: comment.id, reply_id: reply.id)
    end

    test "comments pagination should work", ~m(video user)a do
      body = "fake comment"

      Enum.reduce(1..30, [], fn _, acc ->
        {:ok, value} = CMS.create_comment(:video, video.id, body, user)

        acc ++ [value]
      end)

      {:ok, results} = CMS.list_comments(:video, video.id, %{page: 1, size: 10})

      assert results |> is_valid_pagination?(:raw)
    end

    test "comment reply can be list one-by-one --> by replied user", ~m(comment)a do
      {:ok, user1} = db_insert(:user)
      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)

      {:ok, _} = CMS.reply_comment(:video, comment.id, "reply by user1", user1)

      {:ok, _} = CMS.reply_comment(:video, comment.id, "reply by user2", user2)

      {:ok, _} = CMS.reply_comment(:video, comment.id, "reply by user3", user3)

      {:ok, found_reply1} = CMS.list_replies(:video, comment.id, user1)
      assert user1.id == found_reply1 |> List.first() |> Map.get(:author_id)

      {:ok, found_reply2} = CMS.list_replies(:video, comment.id, user2)
      assert user2.id == found_reply2 |> List.first() |> Map.get(:author_id)

      {:ok, found_reply3} = CMS.list_replies(:video, comment.id, user3)
      assert user3.id == found_reply3 |> List.first() |> Map.get(:author_id)
    end
  end

  describe "[comment Reactions]" do
    test "user can like a comment", ~m(comment user)a do
      {:ok, liked_comment} = CMS.like_comment(:video_comment, comment.id, user)

      {:ok, comment_preload} = ORM.find(VideoComment, liked_comment.id, preload: :likes)

      assert comment_preload.likes |> Enum.any?(&(&1.video_comment_id == comment.id))
    end

    test "user like comment twice fails", ~m(comment user)a do
      {:ok, _} = CMS.like_comment(:video_comment, comment.id, user)
      {:error, _error} = CMS.like_comment(:video_comment, comment.id, user)
      # TODO: fix err_msg later
    end

    test "user can undo a like action", ~m(comment user)a do
      {:ok, like} = CMS.like_comment(:video_comment, comment.id, user)
      {:ok, _} = CMS.undo_like_comment(:video_comment, comment.id, user)

      {:ok, comment_preload} = ORM.find(VideoComment, comment.id, preload: :likes)
      assert false == comment_preload.likes |> Enum.any?(&(&1.id == like.id))
    end

    test "user can dislike a comment", ~m(comment user)a do
      # {:ok, like} = CMS.reaction(:video_comment, :like, comment.id, user.id)
      {:ok, disliked_comment} = CMS.dislike_comment(:video_comment, comment.id, user)

      {:ok, comment_preload} = ORM.find(VideoComment, disliked_comment.id, preload: :dislikes)

      assert comment_preload.dislikes |> Enum.any?(&(&1.video_comment_id == comment.id))
    end

    test "user can undo a dislike action", ~m(comment user)a do
      {:ok, dislike} = CMS.dislike_comment(:video_comment, comment.id, user)
      {:ok, _} = CMS.undo_dislike_comment(:video_comment, comment.id, user)

      {:ok, comment_preload} = ORM.find(VideoComment, comment.id, preload: :dislikes)
      assert false == comment_preload.dislikes |> Enum.any?(&(&1.id == dislike.id))
    end

    test "user can get paged likes of a video comment", ~m(comment)a do
      {:ok, user1} = db_insert(:user)
      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)

      {:ok, _like1} = CMS.like_comment(:video_comment, comment.id, user1)
      {:ok, _like2} = CMS.like_comment(:video_comment, comment.id, user2)
      {:ok, _like3} = CMS.like_comment(:video_comment, comment.id, user3)

      {:ok, results} = CMS.reaction_users(:video_comment, :like, comment.id, %{page: 1, size: 10})

      assert results.entries |> Enum.any?(&(&1.id == user1.id))
      assert results.entries |> Enum.any?(&(&1.id == user2.id))
      assert results.entries |> Enum.any?(&(&1.id == user3.id))
    end
  end
end
