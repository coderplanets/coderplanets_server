defmodule GroupherServer.Test.Delivery.Mention do
  use GroupherServer.TestTools

  import Ecto.Query, warn: false
  import Helper.Utils

  alias Helper.ORM
  alias GroupherServer.{Accounts, Delivery}

  alias Accounts.Model.MentionMail
  alias Delivery.Model.Mention

  describe "mentions" do
    test "user can mention other user" do
      {:ok, [user, user2]} = db_insert_multi(:user, 2)

      mock_mentions_for(user, 1)
      mock_mentions_for(user2, 1)

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Delivery.fetch_mentions(user, filter)

      assert mentions |> is_valid_pagination?(:raw)
      assert mentions |> Map.get(:total_count) == 1
      assert mentions.entries |> List.first() |> Map.get(:to_user_id) == user.id
      assert mentions.entries |> List.first() |> Map.get(:community) == "elixir"
    end

    test "user can fetch mentions and store in own mention mail-box" do
      {:ok, user} = db_insert(:user)

      mock_mentions_for(user, 3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Accounts.fetch_mentions(user, filter)

      {:ok, mention_mails} =
        MentionMail
        |> where([m], m.to_user_id == ^user.id)
        |> where([m], m.read == false)
        |> ORM.paginater(page: 1, size: 10)
        |> done()

      mention_ids =
        mentions.entries
        |> Enum.reduce([], fn m, acc ->
          acc |> Enum.concat([m |> Map.from_struct() |> Map.get(:id)])
        end)

      mention_mail_ids =
        mention_mails.entries
        |> Enum.reduce([], fn m, acc ->
          acc |> Enum.concat([m |> Map.from_struct() |> Map.get(:id)])
        end)

      assert Enum.sort(mention_ids) == Enum.sort(mention_mail_ids)
    end

    test "delete related delivery mentions after user fetch" do
      {:ok, user} = db_insert(:user)

      mock_mentions_for(user, 1)

      filter = %{page: 1, size: 20, read: false}
      {:ok, _mentions} = Accounts.fetch_mentions(user, filter)

      {:ok, mentions} =
        Mention
        |> where([m], m.to_user_id == ^user.id)
        |> ORM.paginater(page: 1, size: 10)
        |> done()

      assert Enum.empty?(mentions.entries)
    end

    test "store user fetch info in delivery records, with last_fetch_unread_time info" do
      {:ok, user} = db_insert(:user)

      mock_mentions_for(user, 3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Accounts.fetch_mentions(user, filter)
      {:ok, record} = Delivery.fetch_record(user)

      latest_insert_time = mentions.entries |> List.first() |> Map.get(:inserted_at) |> to_string

      record_last_fetch_unresd_time =
        record |> Map.get(:mentions_record) |> Map.get("last_fetch_unread_time")

      assert latest_insert_time == record_last_fetch_unresd_time
    end

    test "user can mark one mention as read" do
      {:ok, user} = db_insert(:user)

      mock_mentions_for(user, 3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Accounts.fetch_mentions(user, filter)
      first_mention = mentions.entries |> List.first()
      assert mentions.total_count == 3
      Accounts.mark_mail_read(first_mention, user)

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Accounts.fetch_mentions(user, filter)
      assert mentions.total_count == 2

      filter = %{page: 1, size: 20, read: true}
      {:ok, mentions} = Accounts.fetch_mentions(user, filter)
      assert mentions.total_count == 1
    end

    test "user can mark all unread mentions as read" do
      {:ok, user} = db_insert(:user)

      mock_mentions_for(user, 3)

      filter = %{page: 1, size: 20, read: false}
      {:ok, _mentions} = Accounts.fetch_mentions(user, filter)
      Accounts.mark_mail_read_all(user, :mention)

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Accounts.fetch_mentions(user, filter)

      assert Enum.empty?(mentions.entries)

      filter = %{page: 1, size: 20, read: true}
      {:ok, mentions} = Accounts.fetch_mentions(user, filter)

      assert mentions.total_count == 3
    end
  end
end
