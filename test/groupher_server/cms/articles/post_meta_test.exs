defmodule GroupherServer.Test.CMS.PostMeta do
  @moduledoc false
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Embeds, Author, Post}

  @default_article_meta Embeds.ArticleMeta.default_meta()

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user community post_attrs)a}
  end

  describe "[cms post meta info]" do
    test "can get default meta info", ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = ORM.find_by(Post, id: post.id)
      meta = post.meta |> Map.from_struct() |> Map.delete(:id)

      assert @default_article_meta == meta
    end

    test "is_edited flag should set to true after post updated", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = ORM.find_by(Post, id: post.id)

      assert not post.meta.is_edited

      {:ok, _} = CMS.update_article(post, %{"title" => "new title"})
      {:ok, post} = ORM.find_by(Post, id: post.id)

      assert post.meta.is_edited
    end

    test "post's lock/undo_lock article should work", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      assert not post.meta.is_comment_locked

      {:ok, _} = CMS.lock_article_comments(:post, post.id)
      {:ok, post} = ORM.find_by(Post, id: post.id)

      assert post.meta.is_comment_locked

      {:ok, _} = CMS.undo_lock_article_comments(:post, post.id)
      {:ok, post} = ORM.find_by(Post, id: post.id)

      assert not post.meta.is_comment_locked
    end

    # TODO:
    # test "post with image should have imageCount in meta" do
    # end

    # TODO:
    # test "post with video should have imageCount in meta" do
    # end
  end
end
