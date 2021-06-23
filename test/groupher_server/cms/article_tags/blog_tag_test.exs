defmodule GroupherServer.Test.CMS.ArticleTag.BlogTag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.{Community, ArticleTag, Blog}
  alias Helper.{ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, blog} = db_insert(:blog)
    {:ok, community} = db_insert(:community)
    article_tag_attrs = mock_attrs(:article_tag)
    article_tag_attrs2 = mock_attrs(:article_tag)

    blog_attrs = mock_attrs(:blog)

    {:ok, ~m(user community blog blog_attrs article_tag_attrs article_tag_attrs2)a}
  end

  describe "[blog tag CURD]" do
    test "create article tag with valid data", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      assert article_tag.title == article_tag_attrs.title
      assert article_tag.group == article_tag_attrs.group
    end

    test "can update an article tag", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)

      new_attrs = article_tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    test "create article tag with non-exsit community fails", ~m(article_tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(
                 %Community{id: non_exsit_id()},
                 :blog,
                 article_tag_attrs,
                 user
               )
    end

    test "tag can be deleted", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, article_tag} = ORM.find(ArticleTag, article_tag.id)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      assert {:error, _} = ORM.find(ArticleTag, article_tag.id)
    end

    test "assoc tag should be delete after tag deleted",
         ~m(community blog article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :blog, article_tag_attrs2, user)

      {:ok, blog} = CMS.set_article_tag(:blog, blog.id, article_tag.id)
      {:ok, blog} = CMS.set_article_tag(:blog, blog.id, article_tag2.id)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :article_tags)
      assert exist_in?(article_tag, blog.article_tags)
      assert exist_in?(article_tag2, blog.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :article_tags)
      assert not exist_in?(article_tag, blog.article_tags)
      assert exist_in?(article_tag2, blog.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag2.id)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :article_tags)
      assert not exist_in?(article_tag, blog.article_tags)
      assert not exist_in?(article_tag2, blog.article_tags)
    end
  end

  describe "[create/update blog with tags]" do
    test "can create blog with exsited article tags",
         ~m(community user blog_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :blog, article_tag_attrs2, user)

      blog_with_tags = Map.merge(blog_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:ok, created} = CMS.create_article(community, :blog, blog_with_tags, user)
      {:ok, blog} = ORM.find(Blog, created.id, preload: :article_tags)

      assert exist_in?(article_tag, blog.article_tags)
      assert exist_in?(article_tag2, blog.article_tags)
    end

    test "can not create blog with other community's article tags",
         ~m(community user blog_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, community2} = db_insert(:community)
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :blog, article_tag_attrs2, user)

      blog_with_tags = Map.merge(blog_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:error, reason} = CMS.create_article(community, :blog, blog_with_tags, user)
      is_error?(reason, :invalid_domain_tag)
    end
  end

  describe "[blog tag set /unset]" do
    test "can set a tag ", ~m(community blog article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :blog, article_tag_attrs2, user)

      {:ok, blog} = CMS.set_article_tag(:blog, blog.id, article_tag.id)
      assert blog.article_tags |> length == 1
      assert exist_in?(article_tag, blog.article_tags)

      {:ok, blog} = CMS.set_article_tag(:blog, blog.id, article_tag2.id)
      assert blog.article_tags |> length == 2
      assert exist_in?(article_tag, blog.article_tags)
      assert exist_in?(article_tag2, blog.article_tags)

      {:ok, blog} = CMS.unset_article_tag(:blog, blog.id, article_tag.id)
      assert blog.article_tags |> length == 1
      assert not exist_in?(article_tag, blog.article_tags)
      assert exist_in?(article_tag2, blog.article_tags)

      {:ok, blog} = CMS.unset_article_tag(:blog, blog.id, article_tag2.id)
      assert blog.article_tags |> length == 0
      assert not exist_in?(article_tag, blog.article_tags)
      assert not exist_in?(article_tag2, blog.article_tags)
    end
  end
end
