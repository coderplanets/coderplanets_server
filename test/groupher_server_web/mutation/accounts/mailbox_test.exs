defmodule GroupherServer.Test.Mutaion.Accounts.Mailbox do
  use GroupherServer.TestTools

  alias GroupherServer.Delivery

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user user2 user3)a}
  end

  describe "[mark_read/all]" do
    @query """
    mutation($type: MailboxType, $ids: [Id]) {
      markRead(ids: $ids, type: $type) {
        done
      }
    }
    """
    #
    test "can mark read a mention", ~m(user_conn user user2)a do
      {:ok, _} = mock_mention_for(user, user2)

      {:ok, mentions} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      mention = mentions.entries |> List.first()

      variables = %{ids: [mention.id], type: "MENTION"}
      user_conn |> mutation_result(@query, variables, "markRead")

      {:ok, mentions} = Delivery.fetch(:mention, user, %{page: 1, size: 10, read: true})
      mention = mentions.entries |> List.first()
      assert mention.read
    end

    test "can mark read a notification", ~m(user_conn user user2)a do
      {:ok, _} = mock_notification_for(user, user2)

      {:ok, notifications} = Delivery.fetch(:notification, user, %{page: 1, size: 10})
      notify = notifications.entries |> List.first()

      variables = %{ids: [notify.id], type: "NOTIFICATION"}
      user_conn |> mutation_result(@query, variables, "markRead")

      {:ok, notifications} = Delivery.fetch(:notification, user, %{page: 1, size: 10, read: true})
      notify = notifications.entries |> List.first()

      assert notify.read
    end

    @query """
    mutation($type: MailboxType) {
      markReadAll(type: $type) {
        done
      }
    }
    """

    test "can mark read all mentions", ~m(user_conn user user2 user3)a do
      {:ok, _} = mock_mention_for(user, user2)
      {:ok, _} = mock_mention_for(user, user3)

      {:ok, mentions} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      assert mentions.total_count == 2

      variables = %{type: "MENTION"}
      user_conn |> mutation_result(@query, variables, "markReadAll")

      {:ok, mentions} = Delivery.fetch(:mention, user, %{page: 1, size: 10, read: true})
      assert mentions.total_count == 2
    end

    test "can mark read all notifications", ~m(user_conn user user2)a do
      {:ok, _} = mock_notification_for(user, user2)

      {:ok, notifications} = Delivery.fetch(:notification, user, %{page: 1, size: 10})
      assert notifications.total_count == 1

      variables = %{type: "NOTIFICATION"}
      user_conn |> mutation_result(@query, variables, "markReadAll")

      {:ok, notifications} = Delivery.fetch(:notification, user, %{page: 1, size: 10, read: true})
      assert notifications.total_count == 1
    end
  end
end
