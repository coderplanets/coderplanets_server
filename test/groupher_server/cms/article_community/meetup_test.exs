defmodule GroupherServer.Test.CMS.ArticleCommunity.Meetup do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Meetup

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, meetup} = db_insert(:meetup)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 meetup meetup_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created meetup has origial community info", ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :original_community)

      assert meetup.original_community_id == community.id
    end

    test "meetup can be move to other community", ~m(user community community2 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      assert meetup.original_community_id == community.id

      {:ok, _} = CMS.move_article(:meetup, meetup.id, community2.id)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: [:original_community, :communities])

      assert meetup.original_community.id == community2.id
      assert not is_nil(Enum.find(meetup.communities, &(&1.id == community2.id)))
    end

    @tag :wip
    test "tags should be clean after meetup move to other community",
         ~m(user community community2 meetup_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :meetup, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :meetup, article_tag_attrs2, user)

      {:ok, _meetup} = CMS.set_article_tag(:meetup, meetup.id, article_tag.id)
      {:ok, meetup} = CMS.set_article_tag(:meetup, meetup.id, article_tag2.id)

      assert meetup.article_tags |> length == 2
      assert meetup.original_community_id == community.id

      {:ok, _} = CMS.move_article(:meetup, meetup.id, community2.id)

      {:ok, meetup} =
        ORM.find(Meetup, meetup.id, preload: [:original_community, :communities, :article_tags])

      assert meetup.article_tags |> length == 0
      assert meetup.original_community.id == community2.id
      assert not is_nil(Enum.find(meetup.communities, &(&1.id == community2.id)))
    end

    test "meetup can be mirror to other community", ~m(user community community2 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 1

      assert not is_nil(Enum.find(meetup.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community2.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 2
      assert not is_nil(Enum.find(meetup.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(meetup.communities, &(&1.id == community2.id)))
    end

    test "meetup can be unmirror from community",
         ~m(user community community2 community3 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community2.id)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community3.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:meetup, meetup.id, community3.id)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 2

      assert is_nil(Enum.find(meetup.communities, &(&1.id == community3.id)))
    end

    test "meetup can not unmirror from original community",
         ~m(user community community2 community3 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community2.id)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community3.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:meetup, meetup.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end
  end
end
