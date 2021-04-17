defmodule GroupherServer.Test.Accounts.PublishedComments do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(user user2 community)a}
  end

  describe "[Accounts Publised post comments]" do
    test "fresh user get empty paged published posts", ~m(user)a do
      {:ok, results} = Accounts.published_comments(user, :post, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published posts", ~m(user user2 community)a do
      body = "this is a test comment"
      {:ok, post} = db_insert(:post)
      {:ok, post2} = db_insert(:post)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"

          {:ok, comment} =
            CMS.create_comment(:post, post.id, %{community: community.raw, body: body}, user)

          acc ++ [comment]
        end)

      {:ok, _comment} =
        CMS.create_comment(:post, post2.id, %{community: community.raw, body: body}, user)

      {:ok, _comment} =
        CMS.create_comment(:post, post2.id, %{community: community.raw, body: body}, user2)

      {:ok, results} = Accounts.published_comments(user, :post, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count + 1

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_comment_id))
    end
  end
end
