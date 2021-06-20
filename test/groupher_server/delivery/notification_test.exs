defmodule GroupherServer.Test.Delivery.Notification do
  use GroupherServer.TestTools

  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{Delivery, Repo}

  @notify_group_interval_hour get_config(:general, :notify_group_interval_hour)

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, user4} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    notify_attrs = %{
      type: :post,
      article_id: post.id,
      title: post.title,
      action: :upvote,
      user_id: user.id,
      read: false
    }

    {:ok, ~m(community post user user2 user3 user4 notify_attrs)a}
  end

  # 将插入时间模拟到 @notify_group_interval_hour 之前, 防止折叠
  defp move_insert_at_long_ago(notify) do
    before_inserted_at =
      Timex.shift(Timex.now(), hours: -@notify_group_interval_hour, minutes: -1)
      |> DateTime.truncate(:second)

    notify
    |> Ecto.Changeset.change(%{inserted_at: before_inserted_at})
    |> Repo.update()
  end

  describe "notification curd" do
    test "similar notify should be merged", ~m(user user2 user3 notify_attrs)a do
      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)
      {:ok, _} = Delivery.send(:notify, notify_attrs, user3)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})

      notify = paged_notifies.entries |> List.first()

      assert paged_notifies.total_count == 1

      assert notify.from_users |> length == 2
      assert user2 |> user_exist_in?(notify.from_users)
      assert user3 |> user_exist_in?(notify.from_users)
    end

    test "different notify should not be merged", ~m(user user2 user3 notify_attrs)a do
      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)
      notify_attrs = notify_attrs |> Map.put(:action, :collect)
      {:ok, _} = Delivery.send(:notify, notify_attrs, user3)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})

      assert paged_notifies.total_count == 2

      notify1 = paged_notifies.entries |> List.first()
      notify2 = paged_notifies.entries |> List.last()

      assert user3 |> user_exist_in?(notify1.from_users)
      assert user2 |> user_exist_in?(notify2.from_users)
    end

    test "notify not in @notify_group_interval_hour should not be merged",
         ~m(user user2 user3 notify_attrs)a do
      {:ok, notify} = Delivery.send(:notify, notify_attrs, user2)

      move_insert_at_long_ago(notify)

      {:ok, _} = Delivery.send(:notify, notify_attrs, user3)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})

      assert paged_notifies.total_count == 2

      notify1 = paged_notifies.entries |> List.first()
      notify2 = paged_notifies.entries |> List.last()

      assert user3 |> user_exist_in?(notify1.from_users)
      assert user2 |> user_exist_in?(notify2.from_users)
    end

    test "notify myself got ignored", ~m(user notify_attrs)a do
      {:error, _} = Delivery.send(:notify, notify_attrs, user)
    end
  end

  describe "revoke case" do
    test "can revoke a notification", ~m(user user2  notify_attrs)a do
      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})
      assert paged_notifies.total_count == 1

      Delivery.revoke(:notify, notify_attrs, user2)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})
      assert paged_notifies.total_count == 0
    end

    test "can revoke a multi-user joined notification", ~m(user user2 user3 notify_attrs)a do
      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)
      {:ok, _} = Delivery.send(:notify, notify_attrs, user3)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})
      assert paged_notifies.total_count == 1
      notify = paged_notifies.entries |> List.first()
      assert user_exist_in?(user2, notify.from_users)
      assert user_exist_in?(user3, notify.from_users)

      Delivery.revoke(:notify, notify_attrs, user2)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})
      assert paged_notifies.total_count == 1

      notify = paged_notifies.entries |> List.first()
      assert not user_exist_in?(user2, notify.from_users)
    end

    test "can revoke a multi-user joined notification, long peroid",
         ~m(user user2 user3 notify_attrs)a do
      {:ok, notify} = Delivery.send(:notify, notify_attrs, user2)

      move_insert_at_long_ago(notify)

      {:ok, _} = Delivery.send(:notify, notify_attrs, user3)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})
      assert paged_notifies.total_count == 2

      Delivery.revoke(:notify, notify_attrs, user2)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})
      assert paged_notifies.total_count == 1
      notify = paged_notifies.entries |> List.first()
      assert not user_exist_in?(user2, notify.from_users)
    end

    test "can revoke a multi-user joined notification, long peroid, edge case",
         ~m(user user2 user3 user4 notify_attrs)a do
      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)
      {:ok, notify} = Delivery.send(:notify, notify_attrs, user3)

      move_insert_at_long_ago(notify)

      {:ok, _} = Delivery.send(:notify, notify_attrs, user4)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})
      assert paged_notifies.total_count == 2

      Delivery.revoke(:notify, notify_attrs, user2)

      {:ok, paged_notifies} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})
      assert paged_notifies.total_count == 2
      notify1 = paged_notifies.entries |> List.first()
      notify2 = paged_notifies.entries |> List.last()

      assert not user_exist_in?(user2, notify1.from_users)
      assert not user_exist_in?(user2, notify2.from_users)
    end
  end

  describe "basic type support" do
    test "support upvote", ~m(post user user2 notify_attrs)a do
      notify_attrs
      |> Map.merge(%{
        type: :post,
        article_id: post.id,
        title: post.title,
        action: :upvote,
        user_id: user.id
      })

      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)

      notify_attrs
      |> Map.merge(%{
        type: :comment,
        article_id: post.id,
        comment_id: 11,
        title: post.title,
        action: :upvote,
        user_id: user.id
      })

      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)

      invalid_notify_attrs =
        notify_attrs
        |> Map.merge(%{
          type: :comment,
          article_id: post.id,
          title: post.title,
          action: :upvote,
          user_id: user.id
        })

      {:error, _} = Delivery.send(:notify, invalid_notify_attrs, user2)
    end

    test "support collect", ~m(post user user2 notify_attrs)a do
      notify_attrs
      |> Map.merge(%{
        type: :post,
        article_id: post.id,
        title: post.title,
        action: :collect,
        user_id: user.id
      })

      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)

      invalid_notify_attrs =
        notify_attrs
        |> Map.merge(%{
          article_id: nil,
          title: post.title,
          action: :collect,
          user_id: user.id
        })

      {:error, _} = Delivery.send(:notify, invalid_notify_attrs, user2)
    end

    test "support comment and reply", ~m(post user user2 notify_attrs)a do
      notify_attrs
      |> Map.merge(%{
        type: :post,
        article_id: post.id,
        title: post.title,
        comment_id: 11,
        action: :comment,
        user_id: user.id
      })

      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)

      notify_attrs
      |> Map.merge(%{
        type: :post,
        article_id: post.id,
        comment_id: 11,
        title: post.title,
        action: :reply,
        user_id: user.id
      })

      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)

      invalid_notify_attrs =
        notify_attrs
        |> Map.merge(%{
          type: :post,
          article_id: post.id,
          title: post.title,
          action: :comment,
          user_id: user.id
        })

      {:error, _} = Delivery.send(:notify, invalid_notify_attrs, user2)

      invalid_notify_attrs =
        notify_attrs
        |> Map.merge(%{
          type: :post,
          article_id: post.id,
          title: post.title,
          action: :reply,
          user_id: user.id
        })

      {:error, _} = Delivery.send(:notify, invalid_notify_attrs, user2)
    end

    test "support follow", ~m(user user2)a do
      notify_attrs = %{
        action: :follow,
        user_id: user.id
      }

      {:ok, _} = Delivery.send(:notify, notify_attrs, user2)
    end
  end
end
