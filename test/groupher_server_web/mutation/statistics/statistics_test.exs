defmodule GroupherServer.Test.Mutation.Statistics do
  use GroupherServer.TestTools

  alias GroupherServer.Statistics
  # alias GroupherServer.Accounts.User
  alias Helper.ORM

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    {:ok, community} = db_insert(:community)

    {:ok, ~m(guest_conn user_conn community user)a}
  end

  describe "[statistics user_contribute] " do
    @create_post_query """
    mutation(
      $title: String!
      $body: String!
      $digest: String!
      $length: Int!
      $communityId: ID!
      $articleTags: [Ids]
    ) {
      createPost(
        title: $title
        body: $body
        digest: $digest
        length: $length
        communityId: $communityId
        articleTags: $articleTags
      ) {
        title
        body
        id
      }
    }
    """
    test "user should have contribute list after create a post", ~m(user_conn user community)a do
      post_attr = mock_attrs(:post)
      variables = post_attr |> Map.merge(%{communityId: community.id})

      user_conn |> mutation_result(@create_post_query, variables, "createPost")

      {:ok, contributes} = ORM.find_by(Statistics.UserContribute, user_id: user.id)
      assert contributes.count == 1
    end

    test "community should have contribute list after create a post",
         ~m(user_conn community)a do
      post_attr = mock_attrs(:post)
      variables = post_attr |> Map.merge(%{communityId: community.id})

      user_conn |> mutation_result(@create_post_query, variables, "createPost")

      {:ok, contributes} = ORM.find_by(Statistics.CommunityContribute, community_id: community.id)
      assert contributes.count == 1
    end

    @create_job_query """
    mutation (
      $title: String!,
      $body: String!,
      $digest: String!,
      $length: Int!,
      $communityId: ID!,
      $company: String!,
      $companyLogo: String!
      $salary: String!,
      $exp: String!,
      $education: String!,
      $finance: String!,
      $scale: String!,
      $field: String!,
      $articleTags: [Ids]
    ) {
      createJob(
        title: $title,
        body: $body,
        digest: $digest,
        length: $length,
        communityId: $communityId,
        company: $company,
        companyLogo: $companyLogo,
        salary: $salary,
        exp: $exp,
        education: $education,
        finance: $finance,
        scale: $scale,
        field: $field,
        articleTags: $articleTags
      ) {
        id
        title
        body
        salary
        exp
        education
        field
        communities {
          id
          title
        }
      }
    }
    """
    test "user should have contribute list after create a job", ~m(user_conn user community)a do
      job_attr = mock_attrs(:job)
      variables = job_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      user_conn |> mutation_result(@create_job_query, variables, "createJob")

      {:ok, contributes} = ORM.find_by(Statistics.UserContribute, user_id: user.id)
      assert contributes.count == 1
    end

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
      $articleTags: [Ids]
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
      }
    }
    """
    test "user should have contribute list after create a repo", ~m(user_conn user community)a do
      repo_attr = mock_attrs(:repo)
      variables = repo_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      user_conn |> mutation_result(@create_repo_query, variables, "createRepo")

      {:ok, contributes} = ORM.find_by(Statistics.UserContribute, user_id: user.id)
      assert contributes.count == 1
    end

    @create_comment_query """
    mutation($community: String!, $thread: Thread, $id: ID!, $body: String!) {
      createComment(community: $community, thread: $thread, id: $id, body: $body) {
        id
        body
      }
    }
    """
    test "user should have contribute list after create a comment",
         ~m(user_conn user community)a do
      {:ok, post} = db_insert(:post)
      variables = %{community: community.raw, thread: "POST", id: post.id, body: "this a comment"}
      user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, contributes} = ORM.find_by(Statistics.UserContribute, user_id: user.id)
      assert contributes.count == 1
    end
  end

  describe "[statistics mutaion user_contribute] " do
    @query """
    mutation($userId: ID!) {
      makeContrubute(userId: $userId) {
        date
        count
      }
    }
    """
    test "for guest user makeContribute should add record to user_contribute table",
         ~m(guest_conn user)a do
      variables = %{userId: user.id}
      assert {:error, _} = ORM.find_by(Statistics.UserContribute, user_id: user.id)
      results = guest_conn |> mutation_result(@query, variables, "makeContrubute")
      assert {:ok, _} = ORM.find_by(Statistics.UserContribute, user_id: user.id)

      assert ["count", "date"] == results |> Map.keys()
      assert results["date"] == Timex.today() |> Date.to_iso8601()
      assert results["count"] == 1
    end

    test "makeContribute to same user should update contribute count", ~m(guest_conn user)a do
      variables = %{userId: user.id}
      guest_conn |> mutation_result(@query, variables, "makeContrubute")
      results = guest_conn |> mutation_result(@query, variables, "makeContrubute")
      assert ["count", "date"] == results |> Map.keys()
      assert results["date"] == Timex.today() |> Date.to_iso8601()
      assert results["count"] == 2
    end
  end
end
