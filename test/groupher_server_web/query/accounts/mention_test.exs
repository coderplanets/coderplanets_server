defmodule GroupherServer.Test.Query.Accounts.Mention do
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[accounts mailbox status]" do
    @query """
    query($login: String!) {
      user(login: $login) {
        id
        mailBox {
          hasMail
          totalCount
          mentionCount
          notificationCount
        }
      }
    }
    """

    test "auth user can get it's own mailbox status" do
      {:ok, [user, user2]} = db_insert_multi(:user, 2)

      mock_mentions_for(user, 2)
      mock_mentions_for(user2, 1)

      user_conn = simu_conn(:user, user)

      variables = %{login: user.login}
      results = user_conn |> query_result(@query, variables, "user")
      mail_Box = results["mailBox"]

      assert mail_Box["hasMail"] == true
      assert mail_Box["mentionCount"] == 2
      assert mail_Box["totalCount"] == 2
    end
  end

  describe "[accounts mention]" do
    @query """
    query($filter: MessagesFilter!) {
      mentions(filter: $filter) {
        entries {
          id
          fromUserId
          fromUser {
            id
            avatar
            nickname
          }
          toUserId
          toUser {
            id
            avatar
            nickname
          }
          sourceTitle
          sourcePreview
          sourceType
          community
          read
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "auth user can get it's own mentions" do
      {:ok, [user, user2]} = db_insert_multi(:user, 2)

      mock_mentions_for(user, 1)
      mock_mentions_for(user2, 1)

      user_conn = simu_conn(:user, user)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      results = user_conn |> query_result(@query, variables, "mentions")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 1

      assert results["entries"] |> Enum.any?(&(&1["toUserId"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["community"] == "elixir"))
    end
  end
end
