defmodule GroupherServer.Test.Mutation.Articles.Repo do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Repo, Author}

  setup do
    {:ok, repo} = db_insert(:repo)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, repo)

    {:ok, ~m(user_conn guest_conn owner_conn user community repo)a}
  end

  describe "[mutation repo curd]" do
    @create_repo_query """
    mutation(
      $title: String!,
      $ownerName: String!,
      $ownerUrl: String!,
      $repoUrl: String!,
      $desc: String!,
      $homepageUrl: String,
      $readme: String!,
      $starCount: Int!,
      $issuesCount: Int!,
      $prsCount: Int!,
      $forkCount: Int!,
      $watchCount: Int!,
      $license: String,
      $releaseTag: String,
      $primaryLanguage: RepoLangInput,
      $contributors: [RepoContributorInput],
      $communityId: ID!,
      $articleTags: [Id]
    ) {
      createRepo(
        title: $title,
        ownerName: $ownerName,
        ownerUrl: $ownerUrl,
        repoUrl: $repoUrl,
        desc: $desc,
        homepageUrl: $homepageUrl,
        readme: $readme,
        starCount: $starCount,
        issuesCount: $issuesCount,
        prsCount: $prsCount,
        forkCount: $forkCount,
        watchCount: $watchCount,
        primaryLanguage: $primaryLanguage,
        license: $license,
        releaseTag: $releaseTag,
        contributors: $contributors,
        communityId: $communityId,
        articleTags: $articleTags
      ) {
        id
        title
        desc
        originalCommunity {
          id
        }
      }
    }
    """
    test "create repo with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      repo_attr = mock_attrs(:repo) |> camelize_map_key

      variables = repo_attr |> Map.merge(%{communityId: community.id})
      created = user_conn |> mutation_result(@create_repo_query, variables, "createRepo")
      {:ok, repo} = ORM.find(Repo, created["id"])

      assert created["id"] == to_string(repo.id)

      assert created["id"] == to_string(repo.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)
      assert {:ok, _} = ORM.find_by(Author, user_id: user.id)
    end

    test "create repo with valid tags id list.", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)

      repo_attr = mock_attrs(:repo) |> camelize_map_key

      variables =
        repo_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_repo_query, variables, "createRepo")
      {:ok, repo} = ORM.find(Repo, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, repo.article_tags)
    end

    @update_repo_query """
    mutation(
      $id: ID!,
      $title: String,
      $ownerName: String,
      $ownerUrl: String,
      $repoUrl: String,
      $desc: String,
      $homepageUrl: String,
      $readme: String,
      $starCount: Int,
      $issuesCount: Int,
      $prsCount: Int,
      $forkCount: Int,
      $watchCount: Int,
      $license: String,
      $releaseTag: String,
      $primaryLanguage: RepoLangInput,
      $contributors: [RepoContributorInput],
    ) {
      updateRepo(
        id: $id,
        title: $title,
        ownerName: $ownerName,
        ownerUrl: $ownerUrl,
        repoUrl: $repoUrl,
        desc: $desc,
        homepageUrl: $homepageUrl,
        readme: $readme,
        starCount: $starCount,
        issuesCount: $issuesCount,
        prsCount: $prsCount,
        forkCount: $forkCount,
        watchCount: $watchCount,
        primaryLanguage: $primaryLanguage,
        license: $license,
        releaseTag: $releaseTag,
        contributors: $contributors,
      ) {
        id
        title
        readme
        desc
        originalCommunity {
          id
        }
      }
    }
    """
    test "update git-repo with valid attrs" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)
      {:ok, community} = db_insert(:community)
      repo_attr = mock_attrs(:repo) |> camelize_map_key
      variables = repo_attr |> Map.merge(%{communityId: community.id})
      created = user_conn |> mutation_result(@create_repo_query, variables, "createRepo")
      {:ok, repo} = ORM.find(Repo, created["id"])

      _updated =
        user_conn
        |> mutation_result(
          @update_repo_query,
          %{id: repo.id, title: "new title", readme: "new readme"},
          "updateRepo"
        )

      # assert updated["title"] == "new title"
      # assert updated["readme"] == "new readme"
    end

    test "unauth user update git-repo fails", ~m(user_conn guest_conn repo)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: repo.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@update_repo_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@update_repo_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@update_repo_query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      deleteRepo(id: $id) {
        id
      }
    }
    """

    test "delete a repo by repo's owner", ~m(owner_conn repo)a do
      deleted = owner_conn |> mutation_result(@query, %{id: repo.id}, "deleteRepo")

      assert deleted["id"] == to_string(repo.id)
      assert {:error, _} = ORM.find(Repo, deleted["id"])
    end

    test "can delete a repo by auth user", ~m(repo)a do
      belongs_community_title = repo.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"repo.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: repo.id}, "deleteRepo")

      assert deleted["id"] == to_string(repo.id)
      assert {:error, _} = ORM.find(Repo, deleted["id"])
    end

    test "delete a repo without login user fails", ~m(guest_conn repo)a do
      assert guest_conn |> mutation_get_error?(@query, %{id: repo.id}, ecode(:account_login))
    end

    test "login user with auth passport delete a repo", ~m(repo)a do
      repo_communities_0 = repo.communities |> List.first() |> Map.get(:title)
      passport_rules = %{repo_communities_0 => %{"repo.delete" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: repo.id})

      deleted = rule_conn |> mutation_result(@query, %{id: repo.id}, "deleteRepo")

      assert deleted["id"] == to_string(repo.id)
    end

    test "unauth user delete repo fails", ~m(user_conn guest_conn repo)a do
      variables = %{id: repo.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
