defmodule GroupherServer.Test.CMS.ArticleTag.GuideTag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.{Community, ArticleTag, Guide}
  alias Helper.{ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, guide} = db_insert(:guide)
    {:ok, community} = db_insert(:community)
    article_tag_attrs = mock_attrs(:article_tag)
    article_tag_attrs2 = mock_attrs(:article_tag)

    guide_attrs = mock_attrs(:guide)

    {:ok, ~m(user community guide guide_attrs article_tag_attrs article_tag_attrs2)a}
  end

  describe "[guide tag CURD]" do
    test "create article tag with valid data", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      assert article_tag.title == article_tag_attrs.title
      assert article_tag.group == article_tag_attrs.group
    end

    test "can update an article tag", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)

      new_attrs = article_tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    test "create article tag with non-exsit community fails", ~m(article_tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(
                 %Community{id: non_exsit_id()},
                 :guide,
                 article_tag_attrs,
                 user
               )
    end

    test "tag can be deleted", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, article_tag} = ORM.find(ArticleTag, article_tag.id)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      assert {:error, _} = ORM.find(ArticleTag, article_tag.id)
    end

    test "assoc tag should be delete after tag deleted",
         ~m(community guide article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :guide, article_tag_attrs2, user)

      {:ok, guide} = CMS.set_article_tag(:guide, guide.id, article_tag.id)
      {:ok, guide} = CMS.set_article_tag(:guide, guide.id, article_tag2.id)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :article_tags)
      assert exist_in?(article_tag, guide.article_tags)
      assert exist_in?(article_tag2, guide.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :article_tags)
      assert not exist_in?(article_tag, guide.article_tags)
      assert exist_in?(article_tag2, guide.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag2.id)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :article_tags)
      assert not exist_in?(article_tag, guide.article_tags)
      assert not exist_in?(article_tag2, guide.article_tags)
    end
  end

  describe "[create/update guide with tags]" do
    test "can create guide with exsited article tags",
         ~m(community user guide_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :guide, article_tag_attrs2, user)

      guide_with_tags = Map.merge(guide_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:ok, created} = CMS.create_article(community, :guide, guide_with_tags, user)
      {:ok, guide} = ORM.find(Guide, created.id, preload: :article_tags)

      assert exist_in?(article_tag, guide.article_tags)
      assert exist_in?(article_tag2, guide.article_tags)
    end

    test "can not create guide with other community's article tags",
         ~m(community user guide_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, community2} = db_insert(:community)
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :guide, article_tag_attrs2, user)

      guide_with_tags = Map.merge(guide_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:error, reason} = CMS.create_article(community, :guide, guide_with_tags, user)
      is_error?(reason, :invalid_domain_tag)
    end
  end

  describe "[guide tag set /unset]" do
    test "can set a tag ", ~m(community guide article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :guide, article_tag_attrs2, user)

      {:ok, guide} = CMS.set_article_tag(:guide, guide.id, article_tag.id)
      assert guide.article_tags |> length == 1
      assert exist_in?(article_tag, guide.article_tags)

      {:ok, guide} = CMS.set_article_tag(:guide, guide.id, article_tag2.id)
      assert guide.article_tags |> length == 2
      assert exist_in?(article_tag, guide.article_tags)
      assert exist_in?(article_tag2, guide.article_tags)

      {:ok, guide} = CMS.unset_article_tag(:guide, guide.id, article_tag.id)
      assert guide.article_tags |> length == 1
      assert not exist_in?(article_tag, guide.article_tags)
      assert exist_in?(article_tag2, guide.article_tags)

      {:ok, guide} = CMS.unset_article_tag(:guide, guide.id, article_tag2.id)
      assert guide.article_tags |> length == 0
      assert not exist_in?(article_tag, guide.article_tags)
      assert not exist_in?(article_tag2, guide.article_tags)
    end
  end
end
