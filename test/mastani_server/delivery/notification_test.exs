defmodule MastaniServer.Delivery.NotificationTest do
  use MastaniServer.TestTools

  import Ecto.Query, warn: false
  import Helper.Utils

  alias MastaniServer.Accounts
  alias MastaniServer.Delivery
  alias Helper.ORM

  describe "[delivery notification]" do
    alias Accounts.NotificationMail
    alias Delivery.Notification

    test "user can notify other user" do
      {:ok, [user, user2]} = db_insert_multi(:user, 2)

      mock_notifications_for(user, 1)
      mock_notifications_for(user2, 1)

      filter = %{page: 1, size: 20, read: false}
      {:ok, notifications} = Delivery.fetch_notifications(user, filter)

      assert notifications |> is_valid_pagination?(:raw)
      assert notifications |> Map.get(:total_entries) == 1
      assert user.id == notifications.entries |> List.first() |> Map.get(:to_user_id)
    end

    test "user can fetch notifications and store in own mention mail-box" do
      {:ok, user} = db_insert(:user)

      mock_notifications_for(user, 3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, notifications} = Accounts.fetch_notifications(user, filter)

      {:ok, notification_mails} =
        NotificationMail
        |> where([m], m.to_user_id == ^user.id)
        |> where([m], m.read == false)
        |> ORM.paginater(page: 1, size: 10)
        |> done()

      notification_ids =
        notifications.entries
        |> Enum.reduce([], fn m, acc ->
          acc |> Enum.concat([m |> Map.from_struct() |> Map.get(:id)])
        end)

      notification_mail_ids =
        notification_mails.entries
        |> Enum.reduce([], fn m, acc ->
          acc |> Enum.concat([m |> Map.from_struct() |> Map.get(:id)])
        end)

      assert Enum.sort(notification_ids) == Enum.sort(notification_mail_ids)
    end

    test "delete related delivery notifications after user fetch" do
      {:ok, user} = db_insert(:user)

      mock_notifications_for(user, 3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, _mentions} = Accounts.fetch_notifications(user, filter)

      {:ok, notifications} =
        Notification
        |> where([m], m.to_user_id == ^user.id)
        |> ORM.paginater(page: 1, size: 10)
        |> done()

      assert Enum.empty?(notifications.entries)
    end

    test "store user fetch info in delivery records, with last_fetch_unread_time info" do
      {:ok, user} = db_insert(:user)

      mock_notifications_for(user, 3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, notifications} = Accounts.fetch_notifications(user, filter)
      {:ok, record} = Delivery.fetch_record(user)

      latest_insert_time =
        notifications.entries |> List.first() |> Map.get(:inserted_at) |> to_string

      record_last_fetch_unresd_time =
        record |> Map.get(:notifications_record) |> Map.get("last_fetch_unread_time")

      assert latest_insert_time == record_last_fetch_unresd_time
    end

    test "user can mark one notifications as read" do
      {:ok, user} = db_insert(:user)

      mock_notifications_for(user, 3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, notifications} = Accounts.fetch_notifications(user, filter)
      first_notification = notifications.entries |> List.first()
      assert notifications.total_entries == 3
      Accounts.mark_mail_read(first_notification, user)

      filter = %{page: 1, size: 20, read: false}
      {:ok, notifications} = Accounts.fetch_notifications(user, filter)
      assert notifications.total_entries == 2

      filter = %{page: 1, size: 20, read: true}
      {:ok, notifications} = Accounts.fetch_notifications(user, filter)
      assert notifications.total_entries == 1
    end

    test "user can mark all unread notifications as read" do
      {:ok, user} = db_insert(:user)

      mock_notifications_for(user, 3)

      Accounts.mark_mail_read_all(user, :notification)

      filter = %{page: 1, size: 20, read: false}
      {:ok, notifications} = Accounts.fetch_notifications(user, filter)

      assert Enum.empty?(notifications.entries)

      filter = %{page: 1, size: 20, read: true}
      {:ok, notifications} = Accounts.fetch_notifications(user, filter)
      assert notifications.total_entries == 3
    end
  end
end
