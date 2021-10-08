defmodule GroupherServer.Test.Upvotes.RadarUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    radar_attrs = mock_attrs(:radar, %{community_id: community.id})

    {:ok, ~m(user user2 community radar_attrs)a}
  end

  describe "[cms radar upvote]" do
    test "radar can be upvote && upvotes_count should inc by 1",
         ~m(user user2 community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, article} = CMS.upvote_article(:radar, radar.id, user)
      assert article.id == radar.id
      assert article.upvotes_count == 1

      {:ok, article} = CMS.upvote_article(:radar, radar.id, user2)
      assert article.upvotes_count == 2
    end

    test "upvote a already upvoted radar is fine", ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, article} = CMS.upvote_article(:radar, radar.id, user)
      {:error, _error} = CMS.upvote_article(:radar, radar.id, user)

      assert article.upvotes_count == 1
    end

    test "radar can be undo upvote && upvotes_count should dec by 1",
         ~m(user user2 community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, article} = CMS.upvote_article(:radar, radar.id, user)
      assert article.id == radar.id
      assert article.upvotes_count == 1

      {:ok, article} = CMS.undo_upvote_article(:radar, radar.id, user2)
      assert article.upvotes_count == 0
    end

    test "can get upvotes_users", ~m(user user2 community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, _article} = CMS.upvote_article(:radar, radar.id, user)
      {:ok, _article} = CMS.upvote_article(:radar, radar.id, user2)

      {:ok, users} = CMS.upvoted_users(:radar, radar.id, %{page: 1, size: 2})

      assert users |> is_valid_pagination?(:raw)
      assert user_exist_in?(user, users.entries)
      assert user_exist_in?(user2, users.entries)
    end

    test "radar meta history should be updated after upvote",
         ~m(user user2 community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, article} = CMS.upvote_article(:radar, radar.id, user)
      assert user.id in article.meta.upvoted_user_ids

      {:ok, article} = CMS.upvote_article(:radar, radar.id, user2)
      assert user.id in article.meta.upvoted_user_ids
      assert user2.id in article.meta.upvoted_user_ids
    end

    test "radar meta history should be updated after undo upvote",
         ~m(user user2 community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, _article} = CMS.upvote_article(:radar, radar.id, user)
      {:ok, article} = CMS.upvote_article(:radar, radar.id, user2)

      assert user.id in article.meta.upvoted_user_ids
      assert user2.id in article.meta.upvoted_user_ids

      {:ok, article} = CMS.undo_upvote_article(:radar, radar.id, user2)
      assert user2.id not in article.meta.upvoted_user_ids

      {:ok, article} = CMS.undo_upvote_article(:radar, radar.id, user)
      assert user.id not in article.meta.upvoted_user_ids
    end
  end
end
