defmodule GroupherServer.Test.Accounts.Published.Meetup do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias Helper.ORM

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, meetup} = db_insert(:meetup)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)

    {:ok, ~m(user user2 meetup community community2)a}
  end

  describe "[publised meetups]" do
    test "create meetup should update user published meta", ~m(community user)a do
      meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})
      {:ok, _meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_meetups_count == 2
    end

    test "fresh user get empty paged published meetups", ~m(user)a do
      {:ok, results} = Accounts.paged_published_articles(user, :meetup, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published meetups", ~m(user user2 community community2)a do
      pub_meetups =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})
          {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

          acc ++ [meetup]
        end)

      pub_meetups2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          meetup_attrs = mock_attrs(:meetup, %{community_id: community2.id})
          {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

          acc ++ [meetup]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})
        {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user2)

        acc ++ [meetup]
      end)

      {:ok, results} = Accounts.paged_published_articles(user, :meetup, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_meetup_id = pub_meetups |> Enum.random() |> Map.get(:id)
      random_meetup_id2 = pub_meetups2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_meetup_id))
      assert results.entries |> Enum.any?(&(&1.id == random_meetup_id2))
    end
  end

  describe "[publised meetup comments]" do
    test "can get published article comments", ~m(meetup user)a do
      total_count = 10

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
        acc ++ [comment]
      end)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.paged_published_comments(user, :meetup, filter)

      entries = articles.entries
      article = entries |> List.first()

      assert article.article.id == meetup.id
      assert article.article.title == meetup.title
    end
  end
end
