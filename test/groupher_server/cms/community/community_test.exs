defmodule GroupherServer.Test.CMS.Community do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.Accounts.User
  alias GroupherServer.CMS
  alias CMS.Community

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(user community user2)a}
  end

  describe "[cms community read]" do
    test "read community should inc views", ~m(community)a do
      {:ok, community} = CMS.read_community(%{id: community.id})

      assert community.views == 1
      {:ok, community} = CMS.read_community(%{title: community.title})
      assert community.views == 2
      {:ok, community} = CMS.read_community(%{raw: community.raw})
      assert community.views == 3
    end

    test "read subscribed community should have a flag", ~m(community user user2)a do
      {:ok, _} = CMS.subscribe_community(community, user)

      {:ok, community} = CMS.read_community(%{id: community.id}, user)

      assert community.viewer_has_subscribed
      assert user.id in community.meta.subscribed_user_ids

      {:ok, community} = CMS.read_community(%{id: community.id}, user2)
      assert not community.viewer_has_subscribed
      assert user2.id not in community.meta.subscribed_user_ids
    end
  end

  describe "[cms community subscribe]" do
    # @tag :wip2
    test "user can subscribe a community", ~m(user community)a do
      {:ok, record} = CMS.subscribe_community(community, user)
      assert community.id == record.id
    end

    test "user subscribe a community will update the community's subscribted info",
         ~m(user community)a do
      assert community.subscribers_count == 0
      {:ok, _record} = CMS.subscribe_community(community, user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.subscribers_count == 1

      assert user.id in community.meta.subscribed_user_ids
    end

    test "user unsubscribe a community will update the community's subscribted info",
         ~m(user community)a do
      {:ok, _} = CMS.subscribe_community(community, user)
      {:ok, community} = ORM.find(Community, community.id)
      assert community.subscribers_count == 1
      assert user.id in community.meta.subscribed_user_ids

      {:ok, _} = CMS.unsubscribe_community(community, user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.subscribers_count == 0
      assert user.id not in community.meta.subscribed_user_ids
    end

    test "user can get paged-subscribers of a community", ~m(community)a do
      {:ok, users} = db_insert_multi(:user, 25)

      Enum.each(users, &CMS.subscribe_community(community, %User{id: &1.id}))

      {:ok, results} =
        CMS.community_members(:subscribers, %Community{id: community.id}, %{page: 1, size: 10})

      assert results |> is_valid_pagination?(:raw)
    end
  end
end
