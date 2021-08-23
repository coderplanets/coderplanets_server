defmodule GroupherServer.Test.Accounts.Mailbox do
  use GroupherServer.TestTools
  # TODO import Service.Utils move both helper and github
  # import Helper.Utils

  alias GroupherServer.{Accounts, Delivery}

  @default_mailbox_status Accounts.Model.Embeds.UserMailbox.default_status()

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    {:ok, ~m(post user user2 user3)a}
  end

  describe "mailbox status" do
    test "can get default mailbox status", ~m(user)a do
      {:ok, status} = Accounts.mailbox_status(user)
      assert status == @default_mailbox_status
    end

    test "can get mailbox status", ~m(post user user2)a do
      notify_attrs = %{
        thread: :post,
        article_id: post.id,
        title: post.title,
        action: :upvote,
        user_id: user.id
      }

      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)
      {:ok, user} = Accounts.update_mailbox_status(user.id)

      assert user.mailbox.is_empty == false
      assert user.mailbox.unread_notifications_count == 1
      assert user.mailbox.unread_total_count == 1

      mention_contents = [
        %{
          thread: "POST",
          title: post.title,
          article_id: post.id,
          comment_id: nil,
          read: false,
          block_linker: ["tmp"],
          from_user_id: user2.id,
          to_user_id: user.id,
          inserted_at: post.updated_at |> DateTime.truncate(:second),
          updated_at: post.updated_at |> DateTime.truncate(:second)
        }
      ]

      {:ok, :pass} = Delivery.send(:mention, post, mention_contents, user2)
      {:ok, user} = Accounts.update_mailbox_status(user.id)

      assert user.mailbox.is_empty == false
      assert user.mailbox.unread_notifications_count == 1
      assert user.mailbox.unread_mentions_count == 1
      assert user.mailbox.unread_total_count == 2
    end
  end
end
