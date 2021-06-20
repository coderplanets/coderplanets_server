defmodule GroupherServer.Test.Delivery.Mention do
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

    mention_contents = [
      %{
        thread: "POST",
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

    {:ok, ~m(community post user user2 user3 mention_contents)a}
  end

  describe "mentions" do
    test "can batch send mentions", ~m(post user user2 mention_contents)a do
      {:ok, :pass} = Delivery.send(:mention, post, mention_contents, user)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()

      assert mention.title == post.title
      assert mention.article_id == post.id
      assert mention.user.login == user.login
    end

    @tag :wip
    test "mention multiable times on same article, will only have one record",
         ~m(post user user2 mention_contents)a do
      {:ok, :pass} = Delivery.send(:mention, post, mention_contents, user)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      assert result.total_count == 1

      {:ok, :pass} = Delivery.send(:mention, post, mention_contents, user)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      assert result.total_count == 1
    end

    test "if mention before, update with no mention content will not do mention in final",
         ~m(post user user2 user3 mention_contents)a do
      {:ok, :pass} = Delivery.send(:mention, post, mention_contents, user)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      assert result.total_count == 1

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})
      assert result.total_count == 0

      mention_contents = [
        %{
          thread: "POST",
          title: post.title,
          article_id: post.id,
          comment_id: nil,
          read: false,
          block_linker: ["tmp"],
          from_user_id: user.id,
          to_user_id: user3.id,
          inserted_at: post.updated_at |> DateTime.truncate(:second),
          updated_at: post.updated_at |> DateTime.truncate(:second)
        }
      ]

      {:ok, :pass} = Delivery.send(:mention, post, mention_contents, user)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})
      assert result.total_count == 0

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})
      assert result.total_count == 1
    end
  end
end
