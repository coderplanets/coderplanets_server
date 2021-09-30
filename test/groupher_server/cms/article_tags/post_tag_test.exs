defmodule GroupherServer.Test.CMS.ArticleTag.PostTag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.{Community, ArticleTag, Post}
  alias Helper.{ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)
    article_tag_attrs = mock_attrs(:article_tag)
    article_tag_attrs2 = mock_attrs(:article_tag)

    post_attrs = mock_attrs(:post)

    {:ok, ~m(user community post post_attrs article_tag_attrs article_tag_attrs2)a}
  end

  describe "[post tag CURD]" do
    test "create article tag with valid data", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      assert article_tag.title == article_tag_attrs.title
      assert article_tag.group == article_tag_attrs.group
    end

    test "create article tag with extra & icon data", ~m(community article_tag_attrs user)a do
      tag_attrs = Map.merge(article_tag_attrs, %{extra: ["menuID", "menuID2"], icon: "icon addr"})
      {:ok, article_tag} = CMS.create_article_tag(community, :post, tag_attrs, user)

      assert article_tag.extra == ["menuID", "menuID2"]
      assert article_tag.icon == "icon addr"
    end

    test "can update an article tag", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)

      new_attrs = article_tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    test "create article tag with non-exsit community fails", ~m(article_tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(
                 %Community{id: non_exsit_id()},
                 :post,
                 article_tag_attrs,
                 user
               )
    end

    test "tag can be deleted", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, article_tag} = ORM.find(ArticleTag, article_tag.id)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      assert {:error, _} = ORM.find(ArticleTag, article_tag.id)
    end

    test "assoc tag should be delete after tag deleted",
         ~m(community post article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :post, article_tag_attrs2, user)

      {:ok, post} = CMS.set_article_tag(:post, post.id, article_tag.id)
      {:ok, post} = CMS.set_article_tag(:post, post.id, article_tag2.id)

      {:ok, post} = ORM.find(Post, post.id, preload: :article_tags)
      assert exist_in?(article_tag, post.article_tags)
      assert exist_in?(article_tag2, post.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      {:ok, post} = ORM.find(Post, post.id, preload: :article_tags)
      assert not exist_in?(article_tag, post.article_tags)
      assert exist_in?(article_tag2, post.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag2.id)

      {:ok, post} = ORM.find(Post, post.id, preload: :article_tags)
      assert not exist_in?(article_tag, post.article_tags)
      assert not exist_in?(article_tag2, post.article_tags)
    end
  end

  describe "[create/update post with tags]" do
    test "can create post with exsited article tags",
         ~m(community user post_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :post, article_tag_attrs2, user)

      post_with_tags = Map.merge(post_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:ok, created} = CMS.create_article(community, :post, post_with_tags, user)
      {:ok, post} = ORM.find(Post, created.id, preload: :article_tags)

      assert exist_in?(article_tag, post.article_tags)
      assert exist_in?(article_tag2, post.article_tags)
    end

    test "can not create post with other community's article tags",
         ~m(community user post_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, community2} = db_insert(:community)
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :post, article_tag_attrs2, user)

      post_with_tags = Map.merge(post_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:error, reason} = CMS.create_article(community, :post, post_with_tags, user)
      is_error?(reason, :invalid_domain_tag)
    end
  end

  describe "[post tag set /unset]" do
    test "can set a tag ", ~m(community post article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :post, article_tag_attrs2, user)

      {:ok, post} = CMS.set_article_tag(:post, post.id, article_tag.id)
      assert post.article_tags |> length == 1
      assert exist_in?(article_tag, post.article_tags)

      {:ok, post} = CMS.set_article_tag(:post, post.id, article_tag2.id)
      assert post.article_tags |> length == 2
      assert exist_in?(article_tag, post.article_tags)
      assert exist_in?(article_tag2, post.article_tags)

      {:ok, post} = CMS.unset_article_tag(:post, post.id, article_tag.id)
      assert post.article_tags |> length == 1
      assert not exist_in?(article_tag, post.article_tags)
      assert exist_in?(article_tag2, post.article_tags)

      {:ok, post} = CMS.unset_article_tag(:post, post.id, article_tag2.id)
      assert post.article_tags |> length == 0
      assert not exist_in?(article_tag, post.article_tags)
      assert not exist_in?(article_tag2, post.article_tags)
    end

    test "can not set dup tag ", ~m(community post article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, post} = CMS.set_article_tag(:post, post.id, article_tag.id)
      {:ok, post} = CMS.set_article_tag(:post, post.id, article_tag.id)

      assert post.article_tags |> length == 1
    end
  end
end
