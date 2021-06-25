defmodule GroupherServer.Test.CMS.ArticleTag.WorksTag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.{Community, ArticleTag, Works}
  alias Helper.{ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, works} = db_insert(:works)
    {:ok, community} = db_insert(:community)
    article_tag_attrs = mock_attrs(:article_tag)
    article_tag_attrs2 = mock_attrs(:article_tag)

    works_attrs = mock_attrs(:works)

    {:ok, ~m(user community works works_attrs article_tag_attrs article_tag_attrs2)a}
  end

  describe "[works tag CURD]" do
    test "create article tag with valid data", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      assert article_tag.title == article_tag_attrs.title
      assert article_tag.group == article_tag_attrs.group
    end

    test "can update an article tag", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)

      new_attrs = article_tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    test "create article tag with non-exsit community fails", ~m(article_tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(
                 %Community{id: non_exsit_id()},
                 :works,
                 article_tag_attrs,
                 user
               )
    end

    test "tag can be deleted", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, article_tag} = ORM.find(ArticleTag, article_tag.id)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      assert {:error, _} = ORM.find(ArticleTag, article_tag.id)
    end

    test "assoc tag should be delete after tag deleted",
         ~m(community works article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :works, article_tag_attrs2, user)

      {:ok, works} = CMS.set_article_tag(:works, works.id, article_tag.id)
      {:ok, works} = CMS.set_article_tag(:works, works.id, article_tag2.id)

      {:ok, works} = ORM.find(Works, works.id, preload: :article_tags)
      assert exist_in?(article_tag, works.article_tags)
      assert exist_in?(article_tag2, works.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      {:ok, works} = ORM.find(Works, works.id, preload: :article_tags)
      assert not exist_in?(article_tag, works.article_tags)
      assert exist_in?(article_tag2, works.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag2.id)

      {:ok, works} = ORM.find(Works, works.id, preload: :article_tags)
      assert not exist_in?(article_tag, works.article_tags)
      assert not exist_in?(article_tag2, works.article_tags)
    end
  end

  describe "[create/update works with tags]" do
    test "can create works with exsited article tags",
         ~m(community user works_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :works, article_tag_attrs2, user)

      works_with_tags = Map.merge(works_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:ok, created} = CMS.create_article(community, :works, works_with_tags, user)
      {:ok, works} = ORM.find(Works, created.id, preload: :article_tags)

      assert exist_in?(article_tag, works.article_tags)
      assert exist_in?(article_tag2, works.article_tags)
    end

    test "can not create works with other community's article tags",
         ~m(community user works_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, community2} = db_insert(:community)
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :works, article_tag_attrs2, user)

      works_with_tags = Map.merge(works_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:error, reason} = CMS.create_article(community, :works, works_with_tags, user)
      is_error?(reason, :invalid_domain_tag)
    end
  end

  describe "[works tag set /unset]" do
    test "can set a tag ", ~m(community works article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :works, article_tag_attrs2, user)

      {:ok, works} = CMS.set_article_tag(:works, works.id, article_tag.id)
      assert works.article_tags |> length == 1
      assert exist_in?(article_tag, works.article_tags)

      {:ok, works} = CMS.set_article_tag(:works, works.id, article_tag2.id)
      assert works.article_tags |> length == 2
      assert exist_in?(article_tag, works.article_tags)
      assert exist_in?(article_tag2, works.article_tags)

      {:ok, works} = CMS.unset_article_tag(:works, works.id, article_tag.id)
      assert works.article_tags |> length == 1
      assert not exist_in?(article_tag, works.article_tags)
      assert exist_in?(article_tag2, works.article_tags)

      {:ok, works} = CMS.unset_article_tag(:works, works.id, article_tag2.id)
      assert works.article_tags |> length == 0
      assert not exist_in?(article_tag, works.article_tags)
      assert not exist_in?(article_tag2, works.article_tags)
    end
  end
end
