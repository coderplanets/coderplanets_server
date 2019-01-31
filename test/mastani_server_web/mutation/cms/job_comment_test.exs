defmodule MastaniServer.Test.Mutation.JobComment do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.{CMS, Delivery}

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, comment} =
      CMS.create_comment(:job, job.id, %{community: community.raw, body: "test comment"}, user)

    {:ok, ~m(user_conn guest_conn job user community comment)a}
  end

  describe "[job comment CURD]" do
    @create_comment_query """
    mutation($community: String!, $thread: CmsThread, $id: ID!, $body: String!, $mentionUsers: [Ids]) {
      createComment(community: $community, thread: $thread, id: $id, body: $body, mentionUsers: $mentionUsers) {
        id
        body
      }
    }
    """
    test "login user can create comment to a job", ~m(user_conn community job)a do
      variables = %{community: community.raw, thread: "JOB", id: job.id, body: "this a comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, found} = ORM.find(CMS.JobComment, created["id"])

      assert created["id"] == to_string(found.id)
    end

    test "can mention other user when create comment to job", ~m(user_conn community job)a do
      {:ok, user2} = db_insert(:user)

      comment_body = "this is a comment"

      variables =
        %{community: community.raw, thread: "JOB", id: job.id, body: comment_body}
        |> Map.merge(%{mentionUsers: [%{id: user2.id}]})

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      assert mentions.total_count == 0

      _created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      assert mentions.total_count == 1
      the_mention = mentions.entries |> List.first()

      assert the_mention.source_title == job.title
      assert the_mention.source_type == "comment"
      assert the_mention.parent_id == to_string(job.id)
      assert the_mention.parent_type == "job"
      assert the_mention.source_preview == comment_body
    end

    test "guest user create comment fails", ~m(guest_conn job community)a do
      variables = %{community: community.raw, thread: "JOB", id: job.id, body: "this a comment"}

      assert guest_conn
             |> mutation_get_error?(@create_comment_query, variables, ecode(:account_login))
    end

    @delete_comment_query """
    mutation($thread: CmsThread, $id: ID!) {
      deleteComment(thread: $thread, id: $id) {
        id
        body
      }
    }
    """

    test "comment owner can delete comment", ~m(user community job)a do
      variables = %{community: community.raw, thread: "JOB", id: job.id, body: "this a comment"}

      user_conn = simu_conn(:user, user)
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      deleted =
        user_conn
        |> mutation_result(
          @delete_comment_query,
          %{thread: "JOB", id: created["id"]},
          "deleteComment"
        )

      assert deleted["id"] == created["id"]
    end

    test "unauth user delete comment fails", ~m(user_conn guest_conn community job)a do
      variables = %{community: community.raw, thread: "JOB", id: job.id, body: "this a comment"}
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
      variables = %{community: community.raw, thread: "JOB", id: comment.id, body: "this a reply"}
      replied = user_conn |> mutation_result(@reply_comment_query, variables, "replyComment")

      assert replied["replyTo"] |> Map.get("id") == to_string(comment.id)
    end

    test "guest user reply comment fails", ~m(guest_conn community comment)a do
      variables = %{community: community.raw, thread: "JOB", id: comment.id, body: "this a reply"}

      assert guest_conn
             |> mutation_get_error?(@reply_comment_query, variables, ecode(:account_login))
    end

    test "should mention author when reply to a comment", ~m(community job user)a do
      body = "this is a comment"

      {:ok, comment} =
        CMS.create_comment(:job, job.id, %{community: community.raw, body: body}, user)

      variables = %{
        community: community.raw,
        thread: "JOB",
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
      assert the_mention.parent_id == to_string(job.id)
      assert the_mention.parent_type == "job"
    end

    test "can mention others in a reply", ~m(community job user user_conn)a do
      body = "this is a comment"
      {:ok, user2} = db_insert(:user)

      {:ok, comment} =
        CMS.create_comment(:job, job.id, %{community: community.raw, body: body}, user)

      variables = %{
        community: community.raw,
        thread: "JOB",
        id: comment.id,
        body: "this is a reply",
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
      assert the_mention.source_title == comment.body
      assert the_mention.source_type == "comment_reply"
      assert the_mention.source_preview == "this is a reply"
      assert the_mention.parent_id == to_string(job.id)
      assert the_mention.parent_type == "job"
    end

    test "TODO owner can NOT delete comment when comment has replies" do
    end

    test "TODO owner can NOT edit comment when comment has replies" do
    end

    test "TODO owner can NOT delete comment when comment has created after 3 hours" do
    end
  end

  describe "[job comment reactions]" do
    @like_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      likeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can like a comment", ~m(user_conn comment)a do
      variables = %{thread: "JOB_COMMENT", id: comment.id}
      user_conn |> mutation_result(@like_comment_query, variables, "likeComment")

      {:ok, found} = CMS.JobComment |> ORM.find(comment.id, preload: :likes)

      assert found.likes |> Enum.any?(&(&1.job_comment_id == comment.id))
    end

    @undo_like_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      undoLikeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can undo a like action to comment", ~m(user comment)a do
      variables = %{thread: "JOB_COMMENT", id: comment.id}
      user_conn = simu_conn(:user, user)
      user_conn |> mutation_result(@like_comment_query, variables, "likeComment")

      {:ok, found} = CMS.JobComment |> ORM.find(comment.id, preload: :likes)
      assert found.likes |> Enum.any?(&(&1.job_comment_id == comment.id))

      user_conn |> mutation_result(@undo_like_comment_query, variables, "undoLikeComment")

      {:ok, found} = CMS.JobComment |> ORM.find(comment.id, preload: :likes)
      assert false == found.likes |> Enum.any?(&(&1.job_comment_id == comment.id))
    end

    @dislike_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      dislikeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can dislike a comment", ~m(user_conn comment)a do
      variables = %{thread: "JOB_COMMENT", id: comment.id}
      user_conn |> mutation_result(@dislike_comment_query, variables, "dislikeComment")

      {:ok, found} = CMS.JobComment |> ORM.find(comment.id, preload: :dislikes)

      assert found.dislikes |> Enum.any?(&(&1.job_comment_id == comment.id))
    end

    @undo_dislike_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      undoDislikeComment(thread: $thread, id: $id) {
      id
      }
    }
    """
    test "login user can undo dislike a comment", ~m(user comment)a do
      variables = %{thread: "JOB_COMMENT", id: comment.id}
      user_conn = simu_conn(:user, user)
      user_conn |> mutation_result(@dislike_comment_query, variables, "dislikeComment")
      {:ok, found} = CMS.JobComment |> ORM.find(comment.id, preload: :dislikes)
      assert found.dislikes |> Enum.any?(&(&1.job_comment_id == comment.id))

      user_conn |> mutation_result(@undo_dislike_comment_query, variables, "undoDislikeComment")

      {:ok, found} = CMS.JobComment |> ORM.find(comment.id, preload: :dislikes)
      assert false == found.dislikes |> Enum.any?(&(&1.job_comment_id == comment.id))
    end

    test "unloged user do/undo like/dislike comment fails", ~m(guest_conn comment)a do
      variables = %{thread: "JOB_COMMENT", id: comment.id}

      assert guest_conn |> mutation_get_error?(@like_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@dislike_comment_query, variables)

      assert guest_conn |> mutation_get_error?(@undo_like_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@undo_dislike_comment_query, variables)
    end
  end
end
