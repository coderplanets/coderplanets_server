defmodule GroupherServer.Test.CMS.Post do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community post post_attrs)a}
  end

  describe "[cms post curd]" do
    alias CMS.{Author, Community}

    test "can create post with valid attrs", ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      assert post.title == post_attrs.title
    end

    test "read post should update views and meta viewed_user_list",
         ~m(post_attrs community user user2)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _} = CMS.read_article(:post, post.id, user)
      {:ok, _created} = ORM.find(CMS.Post, post.id)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:post, post.id, user)
      {:ok, created} = ORM.find(CMS.Post, post.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:post, post.id, user2)
      {:ok, created} = ORM.find(CMS.Post, post.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    @tag :wip2
    test "read post should contains viewer_has_xxx state", ~m(post_attrs community user user2)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = CMS.read_article(:post, post.id, user)

      assert not post.viewer_has_collected
      assert not post.viewer_has_upvoted
      assert not post.viewer_has_reported

      {:ok, post} = CMS.read_article(:post, post.id)

      assert not post.viewer_has_collected
      assert not post.viewer_has_upvoted
      assert not post.viewer_has_reported

      {:ok, post} = CMS.read_article(:post, post.id, user2)

      assert not post.viewer_has_collected
      assert not post.viewer_has_upvoted
      assert not post.viewer_has_reported

      {:ok, _} = CMS.upvote_article(:post, post.id, user)
      {:ok, _} = CMS.collect_article(:post, post.id, user)
      {:ok, _} = CMS.report_article(:post, post.id, "reason", "attr_info", user)

      {:ok, post} = CMS.read_article(:post, post.id, user)

      assert post.viewer_has_collected
      assert post.viewer_has_upvoted
      assert post.viewer_has_reported
    end

    test "add user to cms authors, if the user is not exsit in cms authors",
         ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, _} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, author} = ORM.find_by(Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create post with an non-exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:post, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :post, invalid_attrs, user)
    end
  end
end
