defmodule MastaniServer.Test.Mutation.Delivery do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  @account_query """
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
      sysNotifications(filter: $filter) {
        entries {
          id
          read
        }
        totalCount
      }
    }
  }
  """

  describe "[delivery system notification]" do
    @query """
    mutation($sourceTitle: String!, $sourceId: ID!, $sourceType: String!) {
      publishSystemNotification(sourceTitle: $sourceTitle, sourceId: $sourceId ,sourceType: $sourceType) {
        done
      }
    }
    """
    test "auth user can publish system notifications" do
      {:ok, user} = db_insert(:user)

      passport_rules = %{"system_notification.publish" => true}
      # middleware(M.Passport, claim: "cms->editor.set")
      rule_conn = simu_conn(:user, cms: passport_rules)

      user_conn = simu_conn(:user, user)

      variables = %{
        sourceId: "1",
        sourceTitle: "fake post title",
        sourceType: "post"
      }

      # IO.inspect variables, label: "variables"
      %{"done" => true} =
        rule_conn |> mutation_result(@query, variables, "publishSystemNotification")

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@account_query, variables, "account")
      sys_notifications = result["sysNotifications"]

      assert sys_notifications["totalCount"] == 1
    end

    test "unauth user publish system notification fails", ~m(user_conn guest_conn)a do
      variables = %{
        sourceId: "1",
        sourceTitle: "fake post title",
        sourceType: "post"
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!) {
      markSysNotificationRead(id: $id) {
        id
      }
    }
    """
    test "auth user can mark a system notification as read" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      mock_sys_notification(3)
      variables = %{filter: %{page: 1, size: 20, read: false}}

      result = user_conn |> query_result(@account_query, variables, "account")

      notifications = result["sysNotifications"]
      assert notifications["totalCount"] == 3

      first_notification_id = notifications["entries"] |> List.first() |> Map.get("id")
      variables = %{id: first_notification_id}

      user_conn |> mutation_result(@query, variables, "markSysNotificationRead")

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@account_query, variables, "account")

      notifications = result["sysNotifications"]
      assert notifications["totalCount"] == 2

      variables = %{filter: %{page: 1, size: 20, read: true}}

      result = user_conn |> query_result(@account_query, variables, "account")
      notifications = result["sysNotifications"]
      assert notifications["totalCount"] == 1
    end
  end

  describe "[delivery mutations]" do
    @query """
    mutation($userId: ID!, $sourceTitle: String!, $sourceId: ID!, $sourceType: String!, $sourcePreview: String!) {
    mentionSomeone(userId: $userId, sourceTitle: $sourceTitle, sourceId: $sourceId ,sourceType: $sourceType, sourcePreview: $sourcePreview) {
        done
        }
      }
    """
    test "login user can mention someone" do
      {:ok, user} = db_insert(:user)
      {:ok, user2} = db_insert(:user)

      user_conn = simu_conn(:user, user)

      variables = %{
        sourceId: "1",
        sourceTitle: "fake post title",
        sourceType: "post",
        sourcePreview: "preview",
        userId: user2.id
      }

      # IO.inspect variables, label: "variables"
      user_conn |> mutation_result(@query, variables, "mentionSomeone")
      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Accounts.fetch_mentions(user2, filter)

      assert variables.sourceTitle == mentions.entries |> List.first() |> Map.get(:source_title)
      assert user.id == mentions.entries |> List.first() |> Map.get(:from_user_id)
    end

    test "unauth user send mention fails", ~m(guest_conn)a do
      {:ok, user2} = db_insert(:user)

      variables = %{
        sourceId: "1",
        sourceTitle: "fake post title",
        sourceType: "post",
        sourcePreview: "preview",
        userId: user2.id
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      markMentionRead(id: $id) {
        id
      }
    }
    """
    test "user can mark a mention as read" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      mock_mentions_for(user, 3)
      variables = %{filter: %{page: 1, size: 20, read: false}}

      result = user_conn |> query_result(@account_query, variables, "account")
      mentions = result["mentions"]
      assert mentions["totalCount"] == 3

      first_mention_id = mentions["entries"] |> List.first() |> Map.get("id")
      variables = %{id: first_mention_id}

      user_conn |> mutation_result(@query, variables, "markMentionRead")

      variables = %{filter: %{page: 1, size: 20, read: false}}

      result = user_conn |> query_result(@account_query, variables, "account")
      mentions = result["mentions"]
      assert mentions["totalCount"] == 2

      variables = %{filter: %{page: 1, size: 20, read: true}}

      result = user_conn |> query_result(@account_query, variables, "account")
      mentions = result["mentions"]
      assert mentions["totalCount"] == 1
    end

    @query """
    mutation {
      markMentionReadAll {
        done
      }
    }
    """
    test "user can mark all unread mentions as read" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      mock_mentions_for(user, 3)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@account_query, variables, "account")
      mentions = result["mentions"]
      # IO.inspect mentions, label: "mentions"
      assert mentions["totalCount"] == 3

      user_conn |> mutation_result(@query, %{}, "markMentionReadAll")

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@account_query, variables, "account")
      mentions = result["mentions"]

      assert mentions["totalCount"] == 0
    end

    @query """
    mutation($id: ID!) {
      markNotificationRead(id: $id) {
        id
      }
    }
    """
    test "user can mark a notification as read" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      mock_notifications_for(user, 3)
      variables = %{filter: %{page: 1, size: 20, read: false}}

      result = user_conn |> query_result(@account_query, variables, "account")

      notifications = result["notifications"]
      assert notifications["totalCount"] == 3

      first_notification_id = notifications["entries"] |> List.first() |> Map.get("id")
      variables = %{id: first_notification_id}

      user_conn |> mutation_result(@query, variables, "markNotificationRead")

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@account_query, variables, "account")

      notifications = result["notifications"]
      assert notifications["totalCount"] == 2

      variables = %{filter: %{page: 1, size: 20, read: true}}

      result = user_conn |> query_result(@account_query, variables, "account")
      notifications = result["notifications"]
      assert notifications["totalCount"] == 1
    end

    @query """
    mutation {
      markNotificationReadAll {
        done
      }
    }
    """
    test "user can mark all unread notifications as read" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      mock_notifications_for(user, 3)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@account_query, variables, "account")
      notifications = result["notifications"]
      assert notifications["totalCount"] == 3

      user_conn |> mutation_result(@query, %{}, "markNotificationReadAll")

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@account_query, variables, "account")
      notifications = result["notifications"]

      assert notifications["totalCount"] == 0
    end
  end
end
