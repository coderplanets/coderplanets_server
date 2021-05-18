defmodule GroupherServer.Test.CMS do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.{Community, ArticleTag}
  alias Helper.{ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, job} = db_insert(:job)
    {:ok, community} = db_insert(:community)
    tag_attrs = mock_attrs(:tag)
    tag_attrs2 = mock_attrs(:tag)

    {:ok, ~m(user community job tag_attrs tag_attrs2)a}
  end

  describe "[job tag CURD]" do
    test "create article tag with valid data", ~m(community tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :job, tag_attrs, user)
      assert article_tag.title == tag_attrs.title
    end

    test "can update an article tag", ~m(community tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :job, tag_attrs, user)

      new_attrs = tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    test "create article tag with non-exsit community fails", ~m(tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(%Community{id: non_exsit_id()}, :job, tag_attrs, user)
    end

    @tag :wip
    test "tag can be deleted", ~m(community tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :job, tag_attrs, user)
      {:ok, article_tag} = ORM.find(ArticleTag, article_tag.id)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      assert {:error, _} = ORM.find(ArticleTag, article_tag.id)
    end

    @tag :wip2
    test "assoc tag should be delete after tag deleted",
         ~m(community job tag_attrs tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :job, tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :job, tag_attrs2, user)

      {:ok, job} = CMS.set_article_tag(:job, job.id, article_tag.id)
      {:ok, job} = CMS.set_article_tag(:job, job.id, article_tag2.id)

      {:ok, job} = ORM.find(CMS.Job, job.id, preload: :article_tags)
      assert exist_in?(article_tag, job.article_tags)
      assert exist_in?(article_tag2, job.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      {:ok, job} = ORM.find(CMS.Job, job.id, preload: :article_tags)
      assert not exist_in?(article_tag, job.article_tags)
      assert exist_in?(article_tag2, job.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag2.id)

      {:ok, job} = ORM.find(CMS.Job, job.id, preload: :article_tags)
      assert not exist_in?(article_tag, job.article_tags)
      assert not exist_in?(article_tag2, job.article_tags)
    end
  end

  describe "[job tag set /unset]" do
    @tag :wip2
    test "can set a tag ", ~m(community job tag_attrs tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :job, tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :job, tag_attrs2, user)

      {:ok, job} = CMS.set_article_tag(:job, job.id, article_tag.id)
      assert job.article_tags |> length == 1
      assert exist_in?(article_tag, job.article_tags)

      {:ok, job} = CMS.set_article_tag(:job, job.id, article_tag2.id)
      assert job.article_tags |> length == 2
      assert exist_in?(article_tag, job.article_tags)
      assert exist_in?(article_tag2, job.article_tags)

      {:ok, job} = CMS.unset_article_tag(:job, job.id, article_tag.id)
      assert job.article_tags |> length == 1
      assert not exist_in?(article_tag, job.article_tags)
      assert exist_in?(article_tag2, job.article_tags)

      {:ok, job} = CMS.unset_article_tag(:job, job.id, article_tag2.id)
      assert job.article_tags |> length == 0
      assert not exist_in?(article_tag, job.article_tags)
      assert not exist_in?(article_tag2, job.article_tags)
    end
  end
end
