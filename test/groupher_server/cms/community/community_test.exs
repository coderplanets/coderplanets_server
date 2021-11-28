defmodule GroupherServer.Test.CMS.Community do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.Accounts.Model.User
  alias GroupherServer.CMS
  alias CMS.Model.Community

  alias Helper.ORM

  alias CMS.Constant

  @community_normal Constant.pending(:normal)
  @community_applying Constant.pending(:applying)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    article_tag_attrs = mock_attrs(:article_tag)

    {:ok, ~m(user community article_tag_attrs user2)a}
  end

  describe "[cms community apply]" do
    test "apply a community should have pending and can not be read", ~m(user)a do
      attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id, apply_msg: "apply msg"})
      {:ok, community} = CMS.apply_community(attrs)

      assert community.meta.apply_msg == "apply msg"
      assert community.meta.apply_category == "PUBLIC"

      {:ok, community} = ORM.find(Community, community.id)
      assert community.pending == @community_applying
      assert {:error, _} = CMS.read_community(community.raw)

      {:ok, community} = CMS.approve_community_apply(community.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.pending == @community_normal
      assert {:ok, _} = CMS.read_community(community.raw)
    end

    test "apply can be deny", ~m(user)a do
      attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.apply_community(attrs)
      {:ok, community} = CMS.deny_community_apply(community.id)

      {:error, _} = ORM.find(Community, community.id)
    end

    test "user can query has pending apply or not", ~m(user user2)a do
      attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, _community} = CMS.apply_community(attrs)

      {:ok, state} = CMS.has_pending_community_apply?(user)
      assert state.exist

      {:ok, state} = CMS.has_pending_community_apply?(user2)
      assert not state.exist
    end
  end

  describe "[cms community read]" do
    test "read community should inc views", ~m(community)a do
      {:ok, community} = CMS.read_community(community.raw)
      assert community.views == 1
      {:ok, community} = CMS.read_community(community.raw)
      assert community.views == 2
      {:ok, community} = CMS.read_community(community.raw)
      assert community.views == 3
    end

    test "read subscribed community should have a flag", ~m(community user user2)a do
      {:ok, _} = CMS.subscribe_community(community, user)

      {:ok, community} = CMS.read_community(community.raw, user)

      assert community.viewer_has_subscribed
      assert user.id in community.meta.subscribed_user_ids

      {:ok, community} = CMS.read_community(community.raw, user2)
      assert not community.viewer_has_subscribed
      assert user2.id not in community.meta.subscribed_user_ids
    end

    test "read editored community should have a flag", ~m(community user user2)a do
      title = "chief editor"
      {:ok, community} = CMS.set_editor(community, title, user)

      {:ok, community} = CMS.read_community(community.raw, user)
      assert community.viewer_is_editor

      {:ok, community} = CMS.read_community(community.raw, user2)
      assert not community.viewer_is_editor

      {:ok, community} = CMS.unset_editor(community, user)
      {:ok, community} = CMS.read_community(community.raw, user)
      assert not community.viewer_is_editor
    end
  end

  describe "[cms community article_tag]" do
    test "articleTagsCount should work", ~m(community article_tag_attrs user)a do
      {:ok, tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, tag2} = CMS.create_article_tag(community, :job, article_tag_attrs, user)
      {:ok, tag3} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      {:ok, tag4} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.article_tags_count == 4

      {:ok, _} = CMS.delete_article_tag(tag.id)
      {:ok, _} = CMS.delete_article_tag(tag2.id)
      {:ok, _} = CMS.delete_article_tag(tag3.id)
      {:ok, _} = CMS.delete_article_tag(tag4.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.article_tags_count == 0
    end
  end

  describe "[cms community editor]" do
    test "can set editor to a community", ~m(user community)a do
      title = "chief editor"
      {:ok, community} = CMS.set_editor(community, title, user)

      assert community.editors_count == 1
      assert user.id in community.meta.editors_ids
    end

    test "can unset editor to a community", ~m(user community)a do
      title = "chief editor"
      {:ok, community} = CMS.set_editor(community, title, user)
      assert community.editors_count == 1

      {:ok, community} = CMS.unset_editor(community, user)
      assert community.editors_count == 0
      assert user.id not in community.meta.editors_ids
    end
  end

  describe "[cms community subscribe]" do
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
