defmodule GroupherServer.Test.Mutation.PostComment do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Delivery}

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, comment} =
      CMS.create_comment(:post, post.id, %{community: community.raw, body: "test comment"}, user)

    {:ok, ~m(user_conn guest_conn post user community comment)a}
  end

  describe "[post comment CURD]" do
    @create_comment_query """
    mutation(
      $community: String!
      $thread: CmsThread
      $id: ID!
      $body: String!
      $mentionUsers: [Ids]
    ) {
      createComment(
        community: $community
        thread: $thread
        id: $id
        body: $body
        mentionUsers: $mentionUsers
      ) {
        id
        body
      }
    }
    """
    test "login user can create comment to a post", ~m(user_conn community post)a do
      variables = %{community: community.raw, thread: "POST", id: post.id, body: "this a comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, found} = ORM.find(CMS.PostComment, created["id"])

      assert created["id"] == to_string(found.id)
    end

    test "xss comment should be escaped", ~m(user_conn community post)a do
      variables = %{
        community: community.raw,
        thread: "POST",
        id: post.id,
        body: assert_v(:xss_string)
      }

      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, found} = ORM.find(CMS.PostComment, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["body"] == assert_v(:xss_safe_string)
    end

    test "guest user create comment fails", ~m(guest_conn post community)a do
      variables = %{community: community.raw, thread: "POST", id: post.id, body: "this a comment"}

      assert guest_conn
             |> mutation_get_error?(@create_comment_query, variables, ecode(:account_login))
    end

    test "can mention other user when create comment to post", ~m(user_conn community post)a do
      {:ok, user2} = db_insert(:user)

      comment_body = "this is a comment"

      variables =
        %{community: community.raw, thread: "POST", id: post.id, body: comment_body}
        |> Map.merge(%{mentionUsers: [%{id: user2.id}]})

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      assert mentions.total_count == 0

      _created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      assert mentions.total_count == 1
      the_mention = mentions.entries |> List.first()

      assert the_mention.source_title == post.title
      assert the_mention.source_type == "comment"
      assert the_mention.parent_id == to_string(post.id)
      assert the_mention.parent_type == "post"
      assert the_mention.source_preview == comment_body
    end

    @delete_comment_query """
    mutation($thread: CmsThread, $id: ID!) {
      deleteComment(thread: $thread, id: $id) {
        id
        body
      }
    }
    """

    test "comment owner can delete comment", ~m(user community post)a do
      variables = %{community: community.raw, id: post.id, body: "this a comment"}

      user_conn = simu_conn(:user, user)
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      deleted =
        user_conn |> mutation_result(@delete_comment_query, %{id: created["id"]}, "deleteComment")

      assert deleted["id"] == created["id"]
    end

    test "unauth user delete comment fails", ~m(user_conn guest_conn community post)a do
      variables = %{community: community.raw, id: post.id, body: "this a comment"}
      {:ok, owner} = db_insert(:user)
      owner_conn = simu_conn(:user, owner)
      created = owner_conn |> mutation_result(@create_comment_query, variables, "createComment")

      variables = %{id: created["id"]}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@delete_comment_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@delete_comment_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@delete_comment_query, variables, ecode(:passport))
    end

    @reply_comment_query """
    mutation(
      $community: String!
      $thread: CmsThread
      $id: ID!
      $body: String!
      $mentionUsers: [Ids]
    ) {
      replyComment(
        community: $community
        thread: $thread
        id: $id
        body: $body
        mentionUsers: $mentionUsers
      ) {
        id
        body
        replyTo {
          id
        }
      }
    }
    """
    test "login user can reply to a exsit comment", ~m(user_conn community comment)a do
      variables = %{
        community: community.raw,
        thread: "POST",
        id: comment.id,
        body: "this a reply"
      }

      replied = user_conn |> mutation_result(@reply_comment_query, variables, "replyComment")

      assert replied["replyTo"] |> Map.get("id") == to_string(comment.id)
    end

    test "should mention author when reply to a comment", ~m(community post user)a do
      body = "this is a comment"

      {:ok, comment} =
        CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user)

      variables = %{
        community: community.raw,
        thread: "POST",
        id: comment.id,
        body: "this a reply"
      }

      {:ok, user2} = db_insert(:user)
      user_conn2 = simu_conn(:user, user2)
      _replied = user_conn2 |> mutation_result(@reply_comment_query, variables, "replyComment")

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Delivery.fetch_mentions(user, filter)
      assert mentions.total_count == 1
      the_mention = mentions.entries |> List.first()

      assert the_mention.from_user_id == user2.id
      assert the_mention.to_user_id == user.id
      assert the_mention.floor != nil
      assert the_mention.source_title == comment.body
      assert the_mention.source_type == "comment_reply"
      assert the_mention.parent_id == to_string(post.id)
      assert the_mention.parent_type == "post"
    end

    test "can mention others in a reply", ~m(community post user user_conn)a do
      body = "this is a comment" |> String.duplicate(100)
      reply_body = "this is a reply" |> String.duplicate(100)
      {:ok, user2} = db_insert(:user)

      {:ok, comment} =
        CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user)

      variables = %{
        community: community.raw,
        thread: "POST",
        id: comment.id,
        body: reply_body,
        mentionUsers: [%{id: user2.id}]
      }

      _replied = user_conn |> mutation_result(@reply_comment_query, variables, "replyComment")

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      assert mentions.total_count == 1
      the_mention = mentions.entries |> List.first()

      assert the_mention.from_user_id == user.id
      assert the_mention.to_user_id == user2.id
      assert the_mention.floor != nil
      assert String.contains?(comment.body, the_mention.source_title)
      assert the_mention.source_type == "comment_reply"
      assert String.contains?(reply_body, the_mention.source_preview)
      assert the_mention.parent_id == to_string(post.id)
      assert the_mention.parent_type == "post"
    end

    test "guest user reply comment fails", ~m(guest_conn comment)a do
      variables = %{thread: "POST", id: comment.id, body: "this a reply"}

      assert guest_conn |> mutation_get_error?(@reply_comment_query, variables)
    end

    test "TODO owner can NOT delete comment when comment has replies" do
    end

    test "TODO owner can NOT edit comment when comment has replies" do
    end

    test "TODO owner can NOT delete comment when comment has created after 3 hours" do
    end
  end

  describe "[post comment reactions]" do
    @like_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      likeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can like a comment", ~m(user_conn comment)a do
      variables = %{thread: "POST_COMMENT", id: comment.id}
      user_conn |> mutation_result(@like_comment_query, variables, "likeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :likes)

      assert found.likes |> Enum.any?(&(&1.post_comment_id == comment.id))
    end

    @undo_like_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      undoLikeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can undo a like action to comment", ~m(user comment)a do
      variables = %{thread: "POST_COMMENT", id: comment.id}
      user_conn = simu_conn(:user, user)
      user_conn |> mutation_result(@like_comment_query, variables, "likeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :likes)
      assert found.likes |> Enum.any?(&(&1.post_comment_id == comment.id))

      user_conn |> mutation_result(@undo_like_comment_query, variables, "undoLikeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :likes)
      assert false == found.likes |> Enum.any?(&(&1.post_comment_id == comment.id))
    end

    @dislike_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      dislikeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can dislike a comment", ~m(user_conn comment)a do
      variables = %{thread: "POST_COMMENT", id: comment.id}
      user_conn |> mutation_result(@dislike_comment_query, variables, "dislikeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :dislikes)

      assert found.dislikes |> Enum.any?(&(&1.post_comment_id == comment.id))
    end

    @undo_dislike_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      undoDislikeComment(thread: $thread, id: $id) {
      id
      }
    }
    """
    test "login user can undo dislike a comment", ~m(user comment)a do
      variables = %{thread: "POST_COMMENT", id: comment.id}
      user_conn = simu_conn(:user, user)
      user_conn |> mutation_result(@dislike_comment_query, variables, "dislikeComment")
      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :dislikes)
      assert found.dislikes |> Enum.any?(&(&1.post_comment_id == comment.id))

      user_conn |> mutation_result(@undo_dislike_comment_query, variables, "undoDislikeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :dislikes)
      assert false == found.dislikes |> Enum.any?(&(&1.post_comment_id == comment.id))
    end

    test "unloged user do/undo like/dislike comment fails", ~m(guest_conn comment)a do
      variables = %{thread: "POST_COMMENT", id: comment.id}

      assert guest_conn |> mutation_get_error?(@like_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@dislike_comment_query, variables)

      assert guest_conn |> mutation_get_error?(@undo_like_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@undo_dislike_comment_query, variables)
    end
  end
end
