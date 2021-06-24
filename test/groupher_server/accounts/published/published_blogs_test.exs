defmodule GroupherServer.Test.Accounts.Published.Blog do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.ORM

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, blog} = db_insert(:blog)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)

    {:ok, ~m(user user2 blog community community2)a}
  end

  describe "[publised blogs]" do
    test "create blog should update user published meta", ~m(community user)a do
      blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      {:ok, _blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_blogs_count == 2
    end

    test "fresh user get empty paged published blogs", ~m(user)a do
      {:ok, results} = Accounts.paged_published_articles(user, :blog, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published blogs", ~m(user user2 community community2)a do
      pub_blogs =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          blog_attrs = mock_attrs(:blog, %{community_id: community.id})
          {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

          acc ++ [blog]
        end)

      pub_blogs2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          blog_attrs = mock_attrs(:blog, %{community_id: community2.id})
          {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

          acc ++ [blog]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        blog_attrs = mock_attrs(:blog, %{community_id: community.id})
        {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user2)

        acc ++ [blog]
      end)

      {:ok, results} = Accounts.paged_published_articles(user, :blog, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_blog_id = pub_blogs |> Enum.random() |> Map.get(:id)
      random_blog_id2 = pub_blogs2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_blog_id))
      assert results.entries |> Enum.any?(&(&1.id == random_blog_id2))
    end
  end

  describe "[publised blog comments]" do
    test "can get published article comments", ~m(blog user)a do
      total_count = 10

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:blog, blog.id, mock_comment(), user)
        acc ++ [comment]
      end)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.paged_published_comments(user, :blog, filter)

      entries = articles.entries
      article = entries |> List.first()

      assert article.article.id == blog.id
      assert article.article.title == blog.title
    end
  end
end
