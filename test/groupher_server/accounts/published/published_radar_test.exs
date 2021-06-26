defmodule GroupherServer.Test.Accounts.Published.Radar do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.ORM

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, radar} = db_insert(:radar)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)

    {:ok, ~m(user user2 radar community community2)a}
  end

  describe "[publised radars]" do
    test "create radar should update user published meta", ~m(community user)a do
      radar_attrs = mock_attrs(:radar, %{community_id: community.id})
      {:ok, _radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_radars_count == 2
    end

    test "fresh user get empty paged published radars", ~m(user)a do
      {:ok, results} = Accounts.paged_published_articles(user, :radar, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published radars", ~m(user user2 community community2)a do
      pub_radars =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          radar_attrs = mock_attrs(:radar, %{community_id: community.id})
          {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

          acc ++ [radar]
        end)

      pub_radars2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          radar_attrs = mock_attrs(:radar, %{community_id: community2.id})
          {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

          acc ++ [radar]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        radar_attrs = mock_attrs(:radar, %{community_id: community.id})
        {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user2)

        acc ++ [radar]
      end)

      {:ok, results} = Accounts.paged_published_articles(user, :radar, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_radar_id = pub_radars |> Enum.random() |> Map.get(:id)
      random_radar_id2 = pub_radars2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_radar_id))
      assert results.entries |> Enum.any?(&(&1.id == random_radar_id2))
    end
  end

  describe "[publised radar comments]" do
    test "can get published article comments", ~m(radar user)a do
      total_count = 10

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)
        acc ++ [comment]
      end)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.paged_published_comments(user, :radar, filter)

      entries = articles.entries
      article = entries |> List.first()

      assert article.article.id == radar.id
      assert article.article.title == radar.title
    end
  end
end
