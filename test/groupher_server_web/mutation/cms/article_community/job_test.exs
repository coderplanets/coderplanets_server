defmodule GroupherServer.Test.Mutation.ArticleCommunity.Job do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Job

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, job)

    {:ok, ~m(user_conn guest_conn owner_conn community job)a}
  end

  describe "[mirror/unmirror/move job to/from community]" do
    @mirror_article_query """
    mutation($id: ID!, $thread: Thread, $communityId: ID!) {
      mirrorArticle(id: $id, thread: $thread, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can mirror a job to other community", ~m(job)a do
      passport_rules = %{"job.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      variables = %{id: job.id, thread: "JOB", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")
      {:ok, found} = ORM.find(Job, job.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
    end

    test "unauth user cannot mirror a job to a community", ~m(user_conn guest_conn job)a do
      {:ok, community} = db_insert(:community)
      variables = %{id: job.id, thread: "JOB", communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:account_login))

      assert rule_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:passport))
    end

    test "auth user can mirror multi job to other communities", ~m(job)a do
      passport_rules = %{"job.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: job.id, thread: "JOB", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      variables = %{id: job.id, thread: "JOB", communityId: community2.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      {:ok, found} = ORM.find(Job, job.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities
    end

    @unmirror_article_query """
    mutation($id: ID!, $thread: Thread, $communityId: ID!) {
      unmirrorArticle(id: $id, thread: $thread, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can unmirror job to a community", ~m(job)a do
      passport_rules = %{"job.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: job.id, thread: "JOB", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      variables2 = %{id: job.id, thread: "JOB", communityId: community2.id}
      rule_conn |> mutation_result(@mirror_article_query, variables2, "mirrorArticle")

      {:ok, found} = ORM.find(Job, job.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities

      passport_rules = %{"job.community.unmirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@unmirror_article_query, variables, "unmirrorArticle")
      {:ok, found} = ORM.find(Job, job.id, preload: :communities)
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id not in assoc_communities
      assert community2.id in assoc_communities
    end

    @move_article_query """
    mutation($id: ID!, $thread: Thread, $communityId: ID!) {
      moveArticle(id: $id, thread: $thread, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can move job to other community", ~m(job)a do
      passport_rules = %{"job.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: job.id, thread: "JOB", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")
      {:ok, found} = ORM.find(Job, job.id, preload: [:original_community, :communities])
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities

      passport_rules = %{"job.community.move" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      pre_original_community_id = found.original_community.id

      variables = %{id: job.id, thread: "JOB", communityId: community2.id}
      rule_conn |> mutation_result(@move_article_query, variables, "moveArticle")
      {:ok, found} = ORM.find(Job, job.id, preload: [:original_community, :communities])
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert pre_original_community_id not in assoc_communities
      assert community2.id in assoc_communities
      assert community2.id == found.original_community_id

      assert found.original_community.id == community2.id
    end
  end
end
