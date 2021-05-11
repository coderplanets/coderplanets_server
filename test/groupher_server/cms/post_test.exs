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

    @tag :wip3
    test "can create post with valid attrs", ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      assert post.title == post_attrs.title
    end

    @tag :wip3
    test "read post should update views and meta viewed_user_list",
         ~m(post_attrs community user user2)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)
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

    test "created post has origial community info", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :origial_community)

      assert post.origial_community_id == community.id
      assert found.origial_community.id == community.id
    end

    test "can create post with exsited tags", ~m(user community post_attrs)a do
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      post_with_tags = Map.merge(post_attrs, %{tags: [%{id: tag1.id}, %{id: tag2.id}]})

      {:ok, created} = CMS.create_content(community, :post, post_with_tags, user)
      {:ok, found} = ORM.find(CMS.Post, created.id, preload: :tags)

      assert found.tags |> Enum.any?(&(&1.id == tag1.id))
      assert found.tags |> Enum.any?(&(&1.id == tag2.id))
    end

    test "create post with invalid tags fails", ~m(user community post_attrs)a do
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      post_with_tags =
        Map.merge(post_attrs, %{tags: [%{id: tag1.id}, %{id: tag2.id}, %{id: non_exsit_id()}]})

      {:error, _} = CMS.create_content(community, :post, post_with_tags, user)
      {:error, _} = ORM.find_by(CMS.Post, %{title: post_attrs.title})
    end

    test "add user to cms authors, if the user is not exsit in cms authors",
         ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, _} = CMS.create_content(community, :post, post_attrs, user)
      {:ok, author} = ORM.find_by(Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create post with an non-exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:post, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_content(ivalid_community, :post, invalid_attrs, user)
    end
  end
end
