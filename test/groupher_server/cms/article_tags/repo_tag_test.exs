defmodule GroupherServer.Test.CMS.ArticleTag.RepoTag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.{Community, ArticleTag}
  alias Helper.{ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, repo} = db_insert(:repo)
    {:ok, community} = db_insert(:community)
    tag_attrs = mock_attrs(:tag)
    tag_attrs2 = mock_attrs(:tag)

    post_attrs = mock_attrs(:repo)

    {:ok, ~m(user community repo post_attrs tag_attrs tag_attrs2)a}
  end

  describe "[repo tag CURD]" do
    test "create article tag with valid data", ~m(community tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, tag_attrs, user)
      assert article_tag.title == tag_attrs.title
    end

    test "can update an article tag", ~m(community tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, tag_attrs, user)

      new_attrs = tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    test "create article tag with non-exsit community fails", ~m(tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(%Community{id: non_exsit_id()}, :repo, tag_attrs, user)
    end

    @tag :wip
    test "tag can be deleted", ~m(community tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, tag_attrs, user)
      {:ok, article_tag} = ORM.find(ArticleTag, article_tag.id)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      assert {:error, _} = ORM.find(ArticleTag, article_tag.id)
    end

    test "assoc tag should be delete after tag deleted",
         ~m(community repo tag_attrs tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :repo, tag_attrs2, user)

      {:ok, repo} = CMS.set_article_tag(:repo, repo.id, article_tag.id)
      {:ok, repo} = CMS.set_article_tag(:repo, repo.id, article_tag2.id)

      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :article_tags)
      assert exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :article_tags)
      assert not exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag2.id)

      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :article_tags)
      assert not exist_in?(article_tag, repo.article_tags)
      assert not exist_in?(article_tag2, repo.article_tags)
    end
  end

  describe "[create/update repo with tags]" do
    @tag :wip2
    test "can create repo with exsited article tags",
         ~m(community user post_attrs tag_attrs tag_attrs2)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :repo, tag_attrs2, user)

      post_with_tags =
        Map.merge(post_attrs, %{article_tags: [%{id: article_tag.id}, %{id: article_tag2.id}]})

      {:ok, created} = CMS.create_article(community, :repo, post_with_tags, user)
      {:ok, repo} = ORM.find(CMS.Repo, created.id, preload: :article_tags)

      assert exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)
    end

    @tag :wip2
    test "can not create repo with other community's article tags",
         ~m(community user post_attrs tag_attrs tag_attrs2)a do
      {:ok, community2} = db_insert(:community)
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :repo, tag_attrs2, user)

      post_with_tags =
        Map.merge(post_attrs, %{article_tags: [%{id: article_tag.id}, %{id: article_tag2.id}]})

      {:error, reason} = CMS.create_article(community, :repo, post_with_tags, user)
      is_error?(reason, :invalid_domain_tag)
    end
  end

  describe "[repo tag set /unset]" do
    test "can set a tag ", ~m(community repo tag_attrs tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :repo, tag_attrs2, user)

      {:ok, repo} = CMS.set_article_tag(:repo, repo.id, article_tag.id)
      assert repo.article_tags |> length == 1
      assert exist_in?(article_tag, repo.article_tags)

      {:ok, repo} = CMS.set_article_tag(:repo, repo.id, article_tag2.id)
      assert repo.article_tags |> length == 2
      assert exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)

      {:ok, repo} = CMS.unset_article_tag(:repo, repo.id, article_tag.id)
      assert repo.article_tags |> length == 1
      assert not exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)

      {:ok, repo} = CMS.unset_article_tag(:repo, repo.id, article_tag2.id)
      assert repo.article_tags |> length == 0
      assert not exist_in?(article_tag, repo.article_tags)
      assert not exist_in?(article_tag2, repo.article_tags)
    end
  end
end
