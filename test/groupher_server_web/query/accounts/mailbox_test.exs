defmodule GroupherServer.Test.Query.Accounts.Mailbox do
  use GroupherServer.TestTools

  alias GroupherServer.Delivery

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user user2)a}
  end

  defp mock_mention_for(user, from_user) do
    {:ok, post} = db_insert(:post)

    mention_attr = %{
      thread: "POST",
      title: post.title,
      article_id: post.id,
      comment_id: nil,
      block_linker: ["tmp"],
      inserted_at: post.updated_at |> DateTime.truncate(:second),
      updated_at: post.updated_at |> DateTime.truncate(:second)
    }

    mention_contents = [
      Map.merge(mention_attr, %{from_user_id: from_user.id, to_user_id: user.id})
    ]

    Delivery.send(:mention, post, mention_contents, from_user)
  end

  defp mock_nofity_for(user, from_user) do
    {:ok, post} = db_insert(:post)

    notify_attrs = %{
      thread: :post,
      article_id: post.id,
      title: post.title,
      action: :upvote,
      user_id: user.id,
      read: false
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end

  describe "[accounts mailbox status]" do
    @query """
    query($login: String!) {
      user(login: $login) {
        id
        mailbox {
          isEmpty
          unreadTotalCount
          unreadMentionsCount
          unreadNotificationsCount
        }
      }
    }
    """
    @tag :wip
    test "auth user can get it's own default mailbox status", ~m(user)a do
      user_conn = simu_conn(:user, user)

      results = user_conn |> query_result(@query, %{login: user.login}, "user")
      mailbox = results["mailbox"]

      assert mailbox["isEmpty"] == true
      assert mailbox["unreadTotalCount"] == 0
      assert mailbox["unreadMentionsCount"] == 0
      assert mailbox["unreadNotificationsCount"] == 0
    end

    @tag :wip
    test "auth user can get latest mailbox status after being mentioned", ~m(user user2)a do
      {:ok, _} = mock_mention_for(user, user2)

      user_conn = simu_conn(:user, user)

      results = user_conn |> query_result(@query, %{login: user.login}, "user")
      mailbox = results["mailbox"]

      assert mailbox["isEmpty"] == false
      assert mailbox["unreadTotalCount"] == 1
      assert mailbox["unreadMentionsCount"] == 1
      assert mailbox["unreadNotificationsCount"] == 0
    end

    @tag :wip
    test "auth user can get latest mailbox status after being notified", ~m(user user2)a do
      mock_nofity_for(user, user2)

      user_conn = simu_conn(:user, user)

      results = user_conn |> query_result(@query, %{login: user.login}, "user")
      mailbox = results["mailbox"]

      assert mailbox["isEmpty"] == false
      assert mailbox["unreadTotalCount"] == 1
      assert mailbox["unreadMentionsCount"] == 0
      assert mailbox["unreadNotificationsCount"] == 1
    end
  end

  # describe "[accounts mention]" do
  #   @query """
  #   query($filter: MessagesFilter!) {
  #     mentions(filter: $filter) {
  #       entries {
  #         id
  #         fromUserId
  #         fromUser {
  #           id
  #           avatar
  #           nickname
  #         }
  #         toUserId
  #         toUser {
  #           id
  #           avatar
  #           nickname
  #         }
  #         sourceTitle
  #         sourcePreview
  #         sourceType
  #         community
  #         read
  #       }
  #       totalPages
  #       totalCount
  #       pageSize
  #       pageNumber
  #     }
  #   }
  #   """
  #   test "auth user can get it's own mentions" do
  #     {:ok, [user, user2]} = db_insert_multi(:user, 2)

  #     mock_mentions_for(user, 1)
  #     mock_mentions_for(user2, 1)

  #     user_conn = simu_conn(:user, user)

  #     variables = %{filter: %{page: 1, size: 20, read: false}}
  #     results = user_conn |> query_result(@query, variables, "mentions")

  #     assert results |> is_valid_pagination?
  #     assert results["totalCount"] == 1

  #     assert results["entries"] |> Enum.any?(&(&1["toUserId"] == to_string(user.id)))
  #     assert results["entries"] |> Enum.any?(&(&1["community"] == "elixir"))
  #   end
  # end
end
