defmodule GroupherServer.Test.CMS.ArticleTag.RepoTag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.{Community, ArticleTag, Repo}
  alias Helper.{ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, repo} = db_insert(:repo)
    {:ok, community} = db_insert(:community)
    article_tag_attrs = mock_attrs(:article_tag)
    article_tag_attrs2 = mock_attrs(:article_tag)

    repo_attrs = mock_attrs(:repo)

    {:ok, ~m(user community repo repo_attrs article_tag_attrs article_tag_attrs2)a}
  end

  describe "[repo tag CURD]" do
    test "create article tag with valid data", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      assert article_tag.title == article_tag_attrs.title
      assert article_tag.group == article_tag_attrs.group
    end

    test "can update an article tag", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)

      new_attrs = article_tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    test "create article tag with non-exsit community fails", ~m(article_tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(
                 %Community{id: non_exsit_id()},
                 :repo,
                 article_tag_attrs,
                 user
               )
    end

    test "tag can be deleted", ~m(community article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      {:ok, article_tag} = ORM.find(ArticleTag, article_tag.id)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      assert {:error, _} = ORM.find(ArticleTag, article_tag.id)
    end

    test "assoc tag should be delete after tag deleted",
         ~m(community repo article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :repo, article_tag_attrs2, user)

      {:ok, repo} = CMS.set_article_tag(:repo, repo.id, article_tag.id)
      {:ok, repo} = CMS.set_article_tag(:repo, repo.id, article_tag2.id)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :article_tags)
      assert exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag.id)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :article_tags)
      assert not exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)

      {:ok, _} = CMS.delete_article_tag(article_tag2.id)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :article_tags)
      assert not exist_in?(article_tag, repo.article_tags)
      assert not exist_in?(article_tag2, repo.article_tags)
    end
  end

  describe "[create/update repo with tags]" do
    test "can create repo with exsited article tags",
         ~m(community user repo_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :repo, article_tag_attrs2, user)

      repo_with_tags = Map.merge(repo_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:ok, created} = CMS.create_article(community, :repo, repo_with_tags, user)
      {:ok, repo} = ORM.find(Repo, created.id, preload: :article_tags)

      assert exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)
    end

    test "can not create repo with other community's article tags",
         ~m(community user repo_attrs article_tag_attrs article_tag_attrs2)a do
      {:ok, community2} = db_insert(:community)
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :repo, article_tag_attrs2, user)

      repo_with_tags = Map.merge(repo_attrs, %{article_tags: [article_tag.id, article_tag2.id]})

      {:error, reason} = CMS.create_article(community, :repo, repo_with_tags, user)
      is_error?(reason, :invalid_domain_tag)
    end
  end

  describe "[repo tag set /unset]" do
    test "can set a tag ", ~m(community repo article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :repo, article_tag_attrs2, user)

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
