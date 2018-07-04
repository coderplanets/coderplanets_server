defmodule MastaniServer.Test.Query.AccountsMessagesTest do
  use MastaniServer.TestTools

  alias MastaniServer.{Accounts}

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account messages queries]" do
    @query """
    query($filter: MessagesFilter!) {
      account {
        id
        mentions(filter: $filter) {
          entries {
            id
            fromUserId
            toUserId
            read
          }
          totalCount
        }
        notifications(filter: $filter) {
          entries {
            id
            fromUserId
            toUserId
            read
          }
          totalCount
        }
      }
    }
    """
    test "user can get mentions send by others" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      mentions = result["mentions"]
      assert mentions["totalCount"] == 0

      mock_mentions_for(user, 3)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      mentions = result["mentions"]

      assert mentions["totalCount"] == 3
      assert mentions["entries"] |> List.first() |> Map.get("toUserId") == to_string(user.id)
    end

    test "user can get notifications send by others" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      notifications = result["notifications"]
      assert notifications["totalCount"] == 0

      mock_notifications_for(user, 3)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      notifications = result["notifications"]

      assert notifications["totalCount"] == 3
      assert notifications["entries"] |> List.first() |> Map.get("toUserId") == to_string(user.id)
    end
  end
end
