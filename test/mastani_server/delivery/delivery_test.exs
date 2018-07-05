defmodule MastaniServer.Delivery.DeliveryTest do
  use MastaniServer.TestTools

  import Ecto.Query, warn: false
  alias MastaniServer.Delivery

  test "user can check mailbox status" do
    {:ok, user} = db_insert(:user)
    {:ok, mail_box} = Delivery.mailbox_status(user)
    assert mail_box.has_mail == false
    assert mail_box.total_count == 0
    assert mail_box.mention_count == 0
    assert mail_box.notification_count == 0

    mock_mentions_for(user, 2)
    mock_notifications_for(user, 18)
    {:ok, mail_box} = Delivery.mailbox_status(user)
    assert mail_box.has_mail == true
    assert mail_box.total_count == 20
    assert mail_box.mention_count == 2
    assert mail_box.notification_count == 18
  end
end
