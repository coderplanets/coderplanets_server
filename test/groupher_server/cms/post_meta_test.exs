defmodule GroupherServer.Test.CMS.PostMeta do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias Helper.Utils

  @default_article_meta CMS.Delegate.ArticleOperation.default_article_meta()

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user community post_attrs)a}
  end

  describe "[cms post meta info]" do
    alias CMS.{Author, Community, Post}

    @tag :wip
    test "can get default meta info", ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)
      {:ok, post} = ORM.find_by(Post, id: post.id)

      assert @default_article_meta == Utils.keys_to_atoms(post.meta)
    end

    @tag :wip
    test "isEdited flag should set to true after post updated", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)
      {:ok, post} = ORM.find_by(Post, id: post.id)

      assert post.meta["isEdited"] == false

      {:ok, _} = CMS.update_content(post, %{"title" => "new title"})
      {:ok, post} = ORM.find_by(Post, id: post.id)

      assert post.meta["isEdited"] == true
    end

    # test "post with image should have imageCount in meta" do
    # end

    # test "post with video should have imageCount in meta" do
    # end
  end
end
