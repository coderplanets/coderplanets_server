defmodule GroupherServer.Test.Query.OldPostComment do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn post user community)a}
  end

  describe "[post dataloader comment]" do
    @query """
    query($filter: PagedPostsFilter) {
      pagedPosts(filter: $filter) {
        entries {
          id
          title
          commentsParticipatorsCount
          commentsParticipators(filter: { first: 5 }) {
            id
            nickname
          }
          pagedCommentsParticipators {
            entries {
              id
              nickname
            }
            totalCount
          }
          commentsCount
        }
        totalCount
      }
    }
    """
    test "can get comments participators of a post", ~m(user guest_conn)a do
      {:ok, user2} = db_insert(:user)

      {:ok, community} = db_insert(:community)
      {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      comments_participators_count =
        results["entries"] |> List.first() |> Map.get("commentsParticipatorsCount")

      assert comments_participators_count == 0

      body = "this is a test comment"

      assert {:ok, _comment} =
               CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user)

      assert {:ok, _comment} =
               CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user)

      assert {:ok, _comment} =
               CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user2)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      comments_participators_count =
        results["entries"] |> List.first() |> Map.get("commentsParticipatorsCount")

      comments_count = results["entries"] |> List.first() |> Map.get("commentsCount")

      assert comments_participators_count == 2
      assert comments_count == 3

      comments_participators =
        results["entries"] |> List.first() |> Map.get("commentsParticipators")

      assert comments_participators |> Enum.any?(&(&1["id"] == to_string(user.id)))
      assert comments_participators |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end

    test "can get comments participators of a post with multi user", ~m(user guest_conn)a do
      body = "this is a test comment"
      {:ok, community} = db_insert(:community)
      {:ok, post1} = CMS.create_article(community, :post, mock_attrs(:post), user)
      {:ok, post2} = CMS.create_article(community, :post, mock_attrs(:post), user)

      {:ok, users_list} = db_insert_multi(:user, 10)
      {:ok, users_list2} = db_insert_multi(:user, 10)

      Enum.each(
        users_list,
        &CMS.create_comment(:post, post1.id, %{community: community.raw, body: body}, &1)
      )

      Enum.each(
        users_list2,
        &CMS.create_comment(:post, post2.id, %{community: community.raw, body: body}, &1)
      )

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results["entries"] |> List.first() |> Map.get("commentsParticipators") |> length == 5
      assert results["entries"] |> List.first() |> Map.get("commentsParticipatorsCount") == 10

      assert results["entries"] |> List.last() |> Map.get("commentsParticipators") |> length == 5
      assert results["entries"] |> List.last() |> Map.get("commentsParticipatorsCount") == 10
    end

    test "can get paged commetns participators of a post", ~m(user guest_conn)a do
      body = "this is a test comment"

      {:ok, community} = db_insert(:community)
      {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)
      {:ok, users_list} = db_insert_multi(:user, 10)

      Enum.each(
        users_list,
        &CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, &1)
      )

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      participators = results["entries"] |> List.first() |> Map.get("pagedCommentsParticipators")

      assert participators["totalCount"] == 10
    end
  end

  @query """
  query($id: ID!, $thread: Thread, $filter: PagedFilter!) {
    pagedCommentsParticipators(id: $id, thread: $thread, filter: $filter) {
      entries {
        id
        nickname
      }
      totalPages
      totalCount
      pageSize
      pageNumber
    }
  }
  """
  test "can get post's paged commetns participators", ~m(user guest_conn)a do
    body = "this is a test comment"

    {:ok, community} = db_insert(:community)
    {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)
    {:ok, users_list} = db_insert_multi(:user, 10)

    Enum.each(
      users_list,
      &CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, &1)
    )

    variables = %{id: post.id, thread: "POST", filter: %{page: 1, size: 20}}
    results = guest_conn |> query_result(@query, variables, "pagedCommentsParticipators")
    assert results |> is_valid_pagination?()

    assert results["totalCount"] == 10
  end

  # TODO: user can get specific user's replies :paged_replies
  # TODO: filter comment by time / like / reply
  describe "[post comment]" do
    @query """
    query($id: ID!, $filter: CommentsFilter!) {
      pagedComments(id: $id, filter: $filter) {
        entries {
          id
          likesCount
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    @tag :wip
    test "guest user can get a paged comment", ~m(guest_conn post user community)a do
      body = "test comment"

      Enum.reduce(1..30, [], fn _, acc ->
        {:ok, value} =
          CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user)

        acc ++ [value]
      end)

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 30
    end

    @query """
    query($id: ID!, $filter: CommentsFilter!) {
      pagedComments(id: $id, filter: $filter) {
        entries {
          id
          body
          replyTo {
            id
            body
          }
          repliesCount
          replies {
            id
            body
          }
        }
      }
    }
    """
    test "guest user can get replies info", ~m(guest_conn post user community)a do
      body = "test comment"

      {:ok, comment} =
        CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user)

      {:ok, reply} =
        CMS.reply_comment(
          :post,
          comment.id,
          %{community: community.raw, body: "reply body"},
          user
        )

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      found_reply =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(reply.id))) |> List.first()

      # author = found |> Map.get("author")
      assert found["repliesCount"] == 1
      assert found["replies"] |> Enum.any?(&(&1["id"] == to_string(reply.id)))
      assert found["replyTo"] == nil
      assert found_reply["replyTo"] |> Map.get("id") == to_string(comment.id)
    end
  end
end
