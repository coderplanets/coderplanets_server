defmodule GroupherServer.Test.Delivery.SysNotification do
  use GroupherServer.TestTools

  import Ecto.Query, warn: false
  import Helper.Utils

  alias Helper.ORM
  alias GroupherServer.{Accounts, Delivery}

  alias Accounts.Model.SysNotificationMail
  alias Delivery.Model.SysNotification

  describe "[delivery sys notification]" do
    test "user can publish system notification" do
      attrs = mock_attrs(:sys_notification)

      {:ok, sys_notification} = Delivery.publish_system_notification(attrs)
      {:ok, found} = SysNotification |> ORM.find(sys_notification.id)

      assert found.id == sys_notification.id
    end

    test "user can get paged system notifications" do
      {:ok, user} = db_insert(:user)
      mock_sys_notification(10)

      filter = %{page: 1, size: 20}
      {:ok, sys_notification} = Delivery.fetch_sys_notifications(user, filter)

      assert sys_notification |> is_valid_pagination?(:raw)
      assert sys_notification |> Map.get(:total_count) == 10
    end

    test "user can fetch sys notifications and store in own mail-box" do
      {:ok, user} = db_insert(:user)

      mock_sys_notification(3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, sys_notifications} = Accounts.fetch_sys_notifications(user, filter)

      {:ok, sys_notification_mails} =
        SysNotificationMail
        |> where([m], m.user_id == ^user.id)
        |> where([m], m.read == false)
        |> ORM.paginater(page: 1, size: 10)
        |> done()

      sys_notification_ids =
        sys_notifications.entries
        |> Enum.reduce([], fn m, acc ->
          acc |> Enum.concat([m |> Map.from_struct() |> Map.get(:id)])
        end)

      sys_notification_mail_ids =
        sys_notification_mails.entries
        |> Enum.reduce([], fn m, acc ->
          acc |> Enum.concat([m |> Map.from_struct() |> Map.get(:id)])
        end)

      assert Enum.sort(sys_notification_ids) == Enum.sort(sys_notification_mail_ids)
    end

    test "store user fetch info in delivery records, with last_fetch_time info" do
      {:ok, user} = db_insert(:user)

      mock_sys_notification(2)

      filter = %{page: 1, size: 20, read: false}
      {:ok, sys_notifications} = Accounts.fetch_sys_notifications(user, filter)
      {:ok, record} = Delivery.fetch_record(user)

      latest_insert_time =
        sys_notifications.entries |> List.first() |> Map.get(:inserted_at) |> to_string

      record_last_fetch_time =
        record |> Map.get(:sys_notifications_record) |> Map.get("last_fetch_time")

      assert latest_insert_time == record_last_fetch_time
    end

    test "user can mark one sys notifications as read" do
      {:ok, user} = db_insert(:user)

      mock_sys_notification(3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, sys_notifications} = Accounts.fetch_sys_notifications(user, filter)
      assert sys_notifications.total_count == 3

      first_sys_notification = sys_notifications.entries |> List.first()
      Accounts.mark_mail_read(first_sys_notification, user)

      filter = %{page: 1, size: 20, read: false}
      {:ok, sys_notifications} = Accounts.fetch_sys_notifications(user, filter)
      assert sys_notifications.total_count == 2

      filter = %{page: 1, size: 20, read: true}
      {:ok, sys_notifications} = Accounts.fetch_sys_notifications(user, filter)
      assert sys_notifications.total_count == 1
    end
  end
end
