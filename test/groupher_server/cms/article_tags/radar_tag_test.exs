defmodule GroupherServer.Test.CMS.ArticleTag.RadarTag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.{Community, ArticleTag, Radar}
  alias Helper.{ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, radar} = db_insert(:radar)
    {:ok, community} = db_insert(:community)
    article_tag_attrs = mock_attrs(:article_tag)
    article_tag_attrs2 = mock_attrs(:article_tag)

    radar_attrs = mock_attrs(:radar)

    {:ok, ~m(user community radar radar_attrs article_tag_attrs article_tag_attrs2)a}
  end

  describe "[radar tag CURD]" do
    test "create article tag with valid data", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)
      assert article_tag.title == article_tag_attrs.title
      assert article_tag.group == article_tag_attrs.group
    end

    test "can update an article tag", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)

      new_attrs = article_tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    test "create article tag with non-exsit community fails", ~m(article_tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(
                 %Community{id: non_exsit_id()},
                 :radar,
                 article_tag_attrs,
                 user
               )
    end

    test "tag can be deleted", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)
      {:ok, article_tag} = ORM.find(ArticleTag, article_tag.id)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      assert {:error, _} = ORM.find(ArticleTag, article_tag.id)
    end

    test "assoc tag should be delete after tag deleted",
         ~m(community radar article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :radar, article_tag_attrs2, user)

      {:ok, radar} = CMS.set_article_tag(:radar, radar.id, article_tag.id)
      {:ok, radar} = CMS.set_article_tag(:radar, radar.id, article_tag2.id)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :article_tags)
      assert exist_in?(article_tag, radar.article_tags)
      assert exist_in?(article_tag2, radar.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :article_tags)
      assert not exist_in?(article_tag, radar.article_tags)
      assert exist_in?(article_tag2, radar.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag2.id)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :article_tags)
      assert not exist_in?(article_tag, radar.article_tags)
      assert not exist_in?(article_tag2, radar.article_tags)
    end
  end

  describe "[create/update radar with tags]" do
    test "can create radar with exsited article tags",
         ~m(community user radar_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :radar, article_tag_attrs2, user)

      radar_with_tags = Map.merge(radar_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:ok, created} = CMS.create_article(community, :radar, radar_with_tags, user)
      {:ok, radar} = ORM.find(Radar, created.id, preload: :article_tags)

      assert exist_in?(article_tag, radar.article_tags)
      assert exist_in?(article_tag2, radar.article_tags)
    end

    test "can not create radar with other community's article tags",
         ~m(community user radar_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, community2} = db_insert(:community)
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :radar, article_tag_attrs2, user)

      radar_with_tags = Map.merge(radar_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:error, reason} = CMS.create_article(community, :radar, radar_with_tags, user)
      is_error?(reason, :invalid_domain_tag)
    end
  end

  describe "[radar tag set /unset]" do
    test "can set a tag ", ~m(community radar article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :radar, article_tag_attrs2, user)

      {:ok, radar} = CMS.set_article_tag(:radar, radar.id, article_tag.id)
      assert radar.article_tags |> length == 1
      assert exist_in?(article_tag, radar.article_tags)

      {:ok, radar} = CMS.set_article_tag(:radar, radar.id, article_tag2.id)
      assert radar.article_tags |> length == 2
      assert exist_in?(article_tag, radar.article_tags)
      assert exist_in?(article_tag2, radar.article_tags)

      {:ok, radar} = CMS.unset_article_tag(:radar, radar.id, article_tag.id)
      assert radar.article_tags |> length == 1
      assert not exist_in?(article_tag, radar.article_tags)
      assert exist_in?(article_tag2, radar.article_tags)

      {:ok, radar} = CMS.unset_article_tag(:radar, radar.id, article_tag2.id)
      assert radar.article_tags |> length == 0
      assert not exist_in?(article_tag, radar.article_tags)
      assert not exist_in?(article_tag2, radar.article_tags)
    end
  end
end
