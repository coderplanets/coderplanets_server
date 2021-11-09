defmodule GroupherServer.Test.Accounts.Published.Works do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.ORM

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, works} = db_insert(:works)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)

    {:ok, ~m(user user2 works community community2)a}
  end

  describe "[publised works]" do
    test "create works should update user published meta", ~m(community user)a do
      works_attrs = mock_attrs(:works, %{community_id: community.id})
      {:ok, _works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _works} = CMS.create_article(community, :works, works_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_works_count == 2
    end

    test "fresh user get empty paged published works", ~m(user)a do
      {:ok, results} = Accounts.paged_published_articles(user, :works, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published works", ~m(user user2 community community2)a do
      pub_works =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          works_attrs = mock_attrs(:works, %{community_id: community.id})
          {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

          acc ++ [works]
        end)

      pub_works2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          works_attrs = mock_attrs(:works, %{community_id: community2.id})
          {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

          acc ++ [works]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        works_attrs = mock_attrs(:works, %{community_id: community.id})
        {:ok, works} = CMS.create_article(community, :works, works_attrs, user2)

        acc ++ [works]
      end)

      {:ok, results} = Accounts.paged_published_articles(user, :works, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_works_id = pub_works |> Enum.random() |> Map.get(:id)
      random_works_id2 = pub_works2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_works_id))
      assert results.entries |> Enum.any?(&(&1.id == random_works_id2))
    end
  end

  describe "[publised works comments]" do
    test "can get published article comments", ~m(works user)a do
      total_count = 10

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:works, works.id, mock_comment(), user)
        acc ++ [comment]
      end)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.paged_published_comments(user, :works, filter)

      entries = articles.entries
      article = entries |> List.first()

      assert article.article.id == works.id
      assert article.article.title == works.title
    end
  end
end
