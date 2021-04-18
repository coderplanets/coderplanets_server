defmodule GroupherServer.Test.Mutation.Repo do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, repo} = db_insert(:repo)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, repo)

    {:ok, ~m(user_conn guest_conn owner_conn repo)a}
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
      $tags: [Ids]
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
        tags: $tags
      ) {
        id
        title
        desc
        origialCommunity {
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
      {:ok, repo} = ORM.find(CMS.Repo, created["id"])

      assert created["id"] == to_string(repo.id)

      assert created["id"] == to_string(repo.id)
      assert created["origialCommunity"]["id"] == to_string(community.id)
      assert {:ok, _} = ORM.find_by(CMS.Author, user_id: user.id)
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
        origialCommunity {
          id
        }
      }
    }
    """
    @tag :wip2
    test "update git-repo with valid attrs" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)
      {:ok, community} = db_insert(:community)
      repo_attr = mock_attrs(:repo) |> camelize_map_key
      variables = repo_attr |> Map.merge(%{communityId: community.id})
      created = user_conn |> mutation_result(@create_repo_query, variables, "createRepo")
      {:ok, repo} = ORM.find(CMS.Repo, created["id"])

      updated =
        user_conn
        |> mutation_result(
          @update_repo_query,
          %{id: repo.id, title: "new title", readme: "new readme"},
          "updateRepo"
        )

      # assert updated["title"] == "new title"
      # assert updated["readme"] == "new readme"
    end

    test "create repo should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      repo_attr = mock_attrs(:repo, %{readme: assert_v(:xss_string)})

      variables = repo_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      created = user_conn |> mutation_result(@create_repo_query, variables, "createRepo")
      {:ok, repo} = ORM.find(CMS.Repo, created["id"])

      assert repo.readme == assert_v(:xss_safe_string)
    end

    test "unauth user update git-repo fails", ~m(user_conn guest_conn repo)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: repo.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@update_repo_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@update_repo_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@update_repo_query, variables, ecode(:passport))
    end
  end
end
