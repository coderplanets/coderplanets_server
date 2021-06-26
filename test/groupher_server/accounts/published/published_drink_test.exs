defmodule GroupherServer.Test.Accounts.Published.Drink do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.ORM

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, drink} = db_insert(:drink)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)

    {:ok, ~m(user user2 drink community community2)a}
  end

  describe "[publised drinks]" do
    test "create drink should update user published meta", ~m(community user)a do
      drink_attrs = mock_attrs(:drink, %{community_id: community.id})
      {:ok, _drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, _drink} = CMS.create_article(community, :drink, drink_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_drinks_count == 2
    end

    test "fresh user get empty paged published drinks", ~m(user)a do
      {:ok, results} = Accounts.paged_published_articles(user, :drink, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published drinks", ~m(user user2 community community2)a do
      pub_drinks =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          drink_attrs = mock_attrs(:drink, %{community_id: community.id})
          {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

          acc ++ [drink]
        end)

      pub_drinks2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          drink_attrs = mock_attrs(:drink, %{community_id: community2.id})
          {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

          acc ++ [drink]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        drink_attrs = mock_attrs(:drink, %{community_id: community.id})
        {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user2)

        acc ++ [drink]
      end)

      {:ok, results} = Accounts.paged_published_articles(user, :drink, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_drink_id = pub_drinks |> Enum.random() |> Map.get(:id)
      random_drink_id2 = pub_drinks2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_drink_id))
      assert results.entries |> Enum.any?(&(&1.id == random_drink_id2))
    end
  end

  describe "[publised drink comments]" do
    test "can get published article comments", ~m(drink user)a do
      total_count = 10

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:drink, drink.id, mock_comment(), user)
        acc ++ [comment]
      end)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.paged_published_comments(user, :drink, filter)

      entries = articles.entries
      article = entries |> List.first()

      assert article.article.id == drink.id
      assert article.article.title == drink.title
    end
  end
end
