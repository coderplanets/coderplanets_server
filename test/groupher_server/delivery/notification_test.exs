defmodule GroupherServer.Test.Delivery.Notification do
  use GroupherServer.TestTools

  import Ecto.Query, warn: false
  # import Helper.Utils

  alias GroupherServer.Delivery

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    notify = %{
      type: "POST",
      article_id: post.id,
      title: post.title,
      action: "UPVOTE",
      user_id: user.id,
      read: false
      # inserted_at: post.updated_at |> DateTime.truncate(:second),
    }

    {:ok, ~m(community post user user2 user3 notify)a}
  end

  describe "notification curd" do
    @tag :wip
    test "can insert notification.", ~m(post user user2 user3 notify)a do
      {:ok, _} = Delivery.send(:notify, notify, user2)
      {:ok, _} = Delivery.send(:notify, notify, user3)

      {:ok, hello} = Delivery.fetch(:notification, user.id, %{page: 1, size: 10})

      IO.inspect(hello, label: "hello")
    end
  end
end
