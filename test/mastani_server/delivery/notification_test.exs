defmodule MastaniServer.Delivery.NotificationTest do
  # use MastaniServer.TestTools

  # import Ecto.Query, warn: false
  # import Helper.Utils

  # alias MastaniServer.Accounts
  # alias MastaniServer.Delivery
  # alias Helper.ORM

  # describe "mentions" do
  # test "user can mention other user" do
  # {:ok, [user, user2]} = db_insert_multi(:user, 2)

  # mock_mentions_for(user, 1)
  # mock_mentions_for(user2, 1)

  # filter = %{page: 1, size: 20, read: false}
  # {:ok, mentions} = Delivery.fetch_mentions(user, filter)

  # assert mentions |> is_valid_pagination?(:raw)
  # assert mentions |> Map.get(:total_entries) == 1
  # assert user.id == mentions.entries |> List.first() |> Map.get(:to_user_id)
  # end

  # test "user can fetch mentions and store in own mention mail-box" do
  # {:ok, user} = db_insert(:user)

  # mock_mentions_for(user, 3)

  # filter = %{page: 1, size: 20, read: false}
  # {:ok, mentions} = Accounts.fetch_mentions(user, filter)

  # {:ok, mention_mails} =
  # Accounts.MentionMail
  # |> where([m], m.to_user_id == ^user.id)
  # |> where([m], m.read == false)
  # |> ORM.paginater(page: 1, size: 10)
  # |> done()

  # mention_ids =
  # mentions.entries
  # |> Enum.reduce([], fn m, acc ->
  # acc |> Enum.concat([Map.from_struct(m) |> Map.get(:id)])
  # end)

  # mention_mail_ids =
  # mention_mails.entries
  # |> Enum.reduce([], fn m, acc ->
  # acc |> Enum.concat([Map.from_struct(m) |> Map.get(:id)])
  # end)

  # assert mention_ids == mention_mail_ids
  # end

  # test "delete related delivery mentions after user fetch" do
  # {:ok, user} = db_insert(:user)

  # mock_mentions_for(user, 3)

  # filter = %{page: 1, size: 20, read: false}
  # {:ok, _mentions} = Accounts.fetch_mentions(user, filter)

  # {:ok, mentions} =
  # Delivery.Mention
  # |> where([m], m.to_user_id == ^user.id)
  # |> ORM.paginater(page: 1, size: 10)
  # |> done()

  # assert Enum.empty?(mentions.entries)
  # end

  # test "store user fetch info in delivery records, with last_fetch_unread_time info" do
  # {:ok, user} = db_insert(:user)

  # mock_mentions_for(user, 3)

  # filter = %{page: 1, size: 20, read: false}
  # {:ok, mentions} = Accounts.fetch_mentions(user, filter)
  # {:ok, record} = Delivery.fetch_record(user)
  # mentions.entries |> List.last() |> Map.get(:inserted_at)

  # latest_insert_time = mentions.entries |> List.first() |> Map.get(:inserted_at) |> to_string

  # record_last_fetch_unresd_time =
  # record |> Map.get(:mentions_record) |> Map.get("last_fetch_unread_time")

  # assert latest_insert_time == record_last_fetch_unresd_time
  # end

  # test "user can mark one mention as read" do
  # {:ok, user} = db_insert(:user)

  # mock_mentions_for(user, 3)

  # filter = %{page: 1, size: 20, read: false}
  # {:ok, mentions} = Accounts.fetch_mentions(user, filter)
  # first_mention = mentions.entries |> List.first()
  # assert mentions.total_entries == 3
  # Accounts.mark_mail_read(first_mention, user)

  # filter = %{page: 1, size: 20, read: false}
  # {:ok, mentions} = Accounts.fetch_mentions(user, filter)
  # assert mentions.total_entries == 2

  # filter = %{page: 1, size: 20, read: true}
  # {:ok, mentions} = Accounts.fetch_mentions(user, filter)
  # assert mentions.total_entries == 1
  # end

  # test "user can mark all unread mentions as read" do
  # {:ok, user} = db_insert(:user)

  # mock_mentions_for(user, 3)

  # Accounts.mark_mail_read_all(user, :mention)

  # filter = %{page: 1, size: 20, read: false}
  # {:ok, mentions} = Accounts.fetch_mentions(user, filter)

  # assert Enum.empty?(mentions.entries)

  # filter = %{page: 1, size: 20, read: true}
  # {:ok, mentions} = Accounts.fetch_mentions(user, filter)
  # assert mentions.total_entries == 3
  # end
  # end
end
