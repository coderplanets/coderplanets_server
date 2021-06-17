defmodule GroupherServer.Test.Delivery.Mention do
  use GroupherServer.TestTools

  import Ecto.Query, warn: false
  import Helper.Utils

  alias Helper.ORM
  alias GroupherServer.{Accounts, Delivery}

  alias Accounts.Model.MentionMail
  alias Delivery.Model.Mention

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    {:ok, ~m(community post user user2)a}
  end

  # attrs = %{
  #   # should also be article's thread
  #   type: "COMMENT",
  #   title: content.title,
  #   article_id: content.article_id,
  #   comment_id: content.comment_id,
  #   read: false,
  #   block_linker: content.block_linker,
  #   from_user_id: user.id,
  #   to_user_id: to_user.id
  # }

  describe "mentions" do
    @tag :wip
    test "can batch send mentions", ~m(post user user2)a do
      contents = [
        %{
          type: "POST",
          title: post.title,
          article_id: post.id,
          comment_id: nil,
          read: false,
          block_linker: ["tmp"],
          from_user_id: user.id,
          to_user_id: user2.id,
          inserted_at: post.updated_at |> DateTime.truncate(:second),
          updated_at: post.updated_at |> DateTime.truncate(:second)
        }
      ]

      {:ok, :pass} = Delivery.batch_mention(post, contents, user, user2)

      hello = Delivery.paged_mentions(user2, %{page: 1, size: 10})

      IO.inspect(hello, label: "hello --> ")
    end
  end
end
