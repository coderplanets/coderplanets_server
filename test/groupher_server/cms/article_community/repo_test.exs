defmodule GroupherServer.Test.CMS.ArticleCommunity.Repo do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Repo

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, repo} = db_insert(:repo)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    repo_attrs = mock_attrs(:repo, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 repo repo_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created repo has origial community info", ~m(user community repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, repo} = ORM.find(Repo, repo.id, preload: :original_community)

      assert repo.original_community_id == community.id
    end

    test "repo can be move to other community", ~m(user community community2 repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      assert repo.original_community_id == community.id

      {:ok, _} = CMS.move_article(:repo, repo.id, community2.id)
      {:ok, repo} = ORM.find(Repo, repo.id, preload: [:original_community, :communities])

      assert repo.original_community.id == community2.id
      assert exist_in?(community2, repo.communities)
    end

    test "tags should be clean after repo move to other community",
         ~m(user community community2 repo_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :repo, article_tag_attrs2, user)

      {:ok, _repo} = CMS.set_article_tag(:repo, repo.id, article_tag.id)
      {:ok, repo} = CMS.set_article_tag(:repo, repo.id, article_tag2.id)

      assert repo.article_tags |> length == 2
      assert repo.original_community_id == community.id

      {:ok, _} = CMS.move_article(:repo, repo.id, community2.id)

      {:ok, repo} =
        ORM.find(Repo, repo.id, preload: [:original_community, :communities, :article_tags])

      assert repo.article_tags |> length == 0
      assert repo.original_community.id == community2.id
      assert exist_in?(community2, repo.communities)
    end

    test "repo move to other community with new tag",
         ~m(user community community2 repo_attrs)a do
      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(community, :repo, article_tag_attrs0, user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :repo, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :repo, article_tag_attrs2, user)

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _} = CMS.set_article_tag(:repo, repo.id, article_tag0.id)
      {:ok, _} = CMS.set_article_tag(:repo, repo.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:repo, repo.id, article_tag2.id)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: [:article_tags])
      assert repo.article_tags |> length == 3

      {:ok, _} =
        CMS.move_article(:repo, repo.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, repo} =
        ORM.find(Repo, repo.id, preload: [:original_community, :communities, :article_tags])

      assert repo.original_community.id == community2.id
      assert repo.article_tags |> length == 2

      assert not exist_in?(article_tag0, repo.article_tags)
      assert exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)
    end

    test "repo can be mirror to other community", ~m(user community community2 repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 1

      assert exist_in?(community, repo.communities)

      {:ok, _} = CMS.mirror_article(:repo, repo.id, community2.id)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 2

      assert exist_in?(community, repo.communities)
      assert exist_in?(community2, repo.communities)
    end

    test "repo can be mirror to other community with tags",
         ~m(user community community2 repo_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community2, :repo, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :repo, article_tag_attrs2, user)

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, _} =
        CMS.mirror_article(:repo, repo.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :article_tags)
      assert repo.article_tags |> length == 2

      assert exist_in?(article_tag, repo.article_tags)
      assert exist_in?(article_tag2, repo.article_tags)
    end

    test "repo can be unmirror from community",
         ~m(user community community2 community3 repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _} = CMS.mirror_article(:repo, repo.id, community2.id)
      {:ok, _} = CMS.mirror_article(:repo, repo.id, community3.id)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:repo, repo.id, community3.id)
      {:ok, repo} = ORM.find(Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 2

      assert not exist_in?(community3, repo.communities)
    end

    test "repo can be unmirror from community with tags",
         ~m(user community community2 community3 repo_attrs)a do
      article_tag_attrs2 = mock_attrs(:article_tag)
      article_tag_attrs3 = mock_attrs(:article_tag)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :repo, article_tag_attrs2, user)
      {:ok, article_tag3} = CMS.create_article_tag(community3, :repo, article_tag_attrs3, user)

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _} = CMS.mirror_article(:repo, repo.id, community2.id, [article_tag2.id])
      {:ok, _} = CMS.mirror_article(:repo, repo.id, community3.id, [article_tag3.id])

      {:ok, _} = CMS.unmirror_article(:repo, repo.id, community3.id)
      {:ok, repo} = ORM.find(Repo, repo.id, preload: :article_tags)

      assert exist_in?(article_tag2, repo.article_tags)
      assert not exist_in?(article_tag3, repo.article_tags)
    end

    test "repo can not unmirror from original community",
         ~m(user community community2 community3 repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _} = CMS.mirror_article(:repo, repo.id, community2.id)
      {:ok, _} = CMS.mirror_article(:repo, repo.id, community3.id)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:repo, repo.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end

    test "repo can be mirror to home", ~m(community repo_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      assert repo.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:repo, repo.id)
      {:ok, repo} = ORM.find(Repo, repo.id, preload: [:original_community, :communities])

      assert repo.original_community_id == community.id
      assert repo.communities |> length == 2

      assert exist_in?(community, repo.communities)
      assert exist_in?(home_community, repo.communities)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:repo, filter)

      assert exist_in?(repo, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:repo, filter)

      assert exist_in?(repo, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "repo can be mirror to home with tags", ~m(community repo_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(home_community, :repo, article_tag_attrs0, user)

      {:ok, article_tag} = CMS.create_article_tag(home_community, :repo, article_tag_attrs, user)

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      assert repo.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:repo, repo.id, [article_tag0.id, article_tag.id])

      {:ok, repo} =
        ORM.find(Repo, repo.id, preload: [:original_community, :communities, :article_tags])

      assert repo.original_community_id == community.id
      assert repo.communities |> length == 2

      assert exist_in?(community, repo.communities)
      assert exist_in?(home_community, repo.communities)

      assert repo.article_tags |> length == 2
      assert exist_in?(article_tag0, repo.article_tags)
      assert exist_in?(article_tag, repo.article_tags)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:repo, filter)

      assert exist_in?(repo, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:repo, filter)

      assert exist_in?(repo, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "repo can be move to blackhole", ~m(community repo_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      assert repo.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:repo, repo.id)
      {:ok, repo} = ORM.find(Repo, repo.id, preload: [:original_community, :communities])

      assert repo.original_community.id == blackhole_community.id
      assert repo.communities |> length == 1

      assert exist_in?(blackhole_community, repo.communities)

      filter = %{page: 1, size: 10, community: blackhole_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:repo, filter)

      assert exist_in?(repo, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "repo can be move to blackhole with tags", ~m(community repo_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(blackhole_community, :repo, article_tag_attrs0, user)

      {:ok, article_tag} =
        CMS.create_article_tag(blackhole_community, :repo, article_tag_attrs, user)

      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _} = CMS.set_article_tag(:repo, repo.id, article_tag0.id)

      assert repo.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:repo, repo.id, [article_tag.id])

      {:ok, repo} =
        ORM.find(Repo, repo.id, preload: [:original_community, :communities, :article_tags])

      assert repo.original_community.id == blackhole_community.id
      assert repo.communities |> length == 1
      assert repo.article_tags |> length == 1

      assert exist_in?(blackhole_community, repo.communities)
      assert exist_in?(article_tag, repo.article_tags)
    end
  end
end
