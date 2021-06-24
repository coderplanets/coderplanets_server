defmodule GroupherServer.Test.Accounts.Published.Post do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.ORM

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)

    {:ok, ~m(user user2 post community community2)a}
  end

  describe "[publised posts]" do
    test "create post should update user published meta", ~m(community user)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id})
      {:ok, _post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_posts_count == 2
    end

    test "fresh user get empty paged published posts", ~m(user)a do
      {:ok, results} = Accounts.paged_published_articles(user, :post, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published posts", ~m(user user2 community community2)a do
      pub_posts =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          post_attrs = mock_attrs(:post, %{community_id: community.id})
          {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

          acc ++ [post]
        end)

      pub_posts2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          post_attrs = mock_attrs(:post, %{community_id: community2.id})
          {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

          acc ++ [post]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        post_attrs = mock_attrs(:post, %{community_id: community.id})
        {:ok, post} = CMS.create_article(community, :post, post_attrs, user2)

        acc ++ [post]
      end)

      {:ok, results} = Accounts.paged_published_articles(user, :post, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_post_id = pub_posts |> Enum.random() |> Map.get(:id)
      random_post_id2 = pub_posts2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_post_id))
      assert results.entries |> Enum.any?(&(&1.id == random_post_id2))
    end
  end

  describe "[publised post comments]" do
    test "can get published article comments", ~m(post user)a do
      total_count = 10

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
        acc ++ [comment]
      end)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.paged_published_comments(user, :post, filter)

      entries = articles.entries
      article = entries |> List.first()

      assert article.article.id == post.id
      assert article.article.title == post.title
    end
  end
end
