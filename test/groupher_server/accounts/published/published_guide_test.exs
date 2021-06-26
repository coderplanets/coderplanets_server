defmodule GroupherServer.Test.Accounts.Published.Guide do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.ORM

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, guide} = db_insert(:guide)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)

    {:ok, ~m(user user2 guide community community2)a}
  end

  describe "[publised guides]" do
    test "create guide should update user published meta", ~m(community user)a do
      guide_attrs = mock_attrs(:guide, %{community_id: community.id})
      {:ok, _guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _guide} = CMS.create_article(community, :guide, guide_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_guides_count == 2
    end

    test "fresh user get empty paged published guides", ~m(user)a do
      {:ok, results} = Accounts.paged_published_articles(user, :guide, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published guides", ~m(user user2 community community2)a do
      pub_guides =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          guide_attrs = mock_attrs(:guide, %{community_id: community.id})
          {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

          acc ++ [guide]
        end)

      pub_guides2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          guide_attrs = mock_attrs(:guide, %{community_id: community2.id})
          {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

          acc ++ [guide]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        guide_attrs = mock_attrs(:guide, %{community_id: community.id})
        {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user2)

        acc ++ [guide]
      end)

      {:ok, results} = Accounts.paged_published_articles(user, :guide, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_guide_id = pub_guides |> Enum.random() |> Map.get(:id)
      random_guide_id2 = pub_guides2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_guide_id))
      assert results.entries |> Enum.any?(&(&1.id == random_guide_id2))
    end
  end

  describe "[publised guide comments]" do
    test "can get published article comments", ~m(guide user)a do
      total_count = 10

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:guide, guide.id, mock_comment(), user)
        acc ++ [comment]
      end)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.paged_published_comments(user, :guide, filter)

      entries = articles.entries
      article = entries |> List.first()

      assert article.article.id == guide.id
      assert article.article.title == guide.title
    end
  end
end
