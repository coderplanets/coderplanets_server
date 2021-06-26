defmodule GroupherServer.Test.Mutation.ArticleCommunity.Guide do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Guide

  setup do
    {:ok, guide} = db_insert(:guide)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, guide)

    {:ok, ~m(user_conn guest_conn owner_conn community guide)a}
  end

  describe "[mirror/unmirror/move guide to/from community]" do
    @mirror_article_query """
    mutation($id: ID!, $thread: Thread, $communityId: ID!) {
      mirrorArticle(id: $id, thread: $thread, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can mirror a guide to other community", ~m(guide)a do
      passport_rules = %{"guide.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      variables = %{id: guide.id, thread: "GUIDE", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")
      {:ok, found} = ORM.find(Guide, guide.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
    end

    test "unauth user cannot mirror a guide to a community", ~m(user_conn guest_conn guide)a do
      {:ok, community} = db_insert(:community)
      variables = %{id: guide.id, thread: "GUIDE", communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:account_login))

      assert rule_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:passport))
    end

    test "auth user can mirror multi guide to other communities", ~m(guide)a do
      passport_rules = %{"guide.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: guide.id, thread: "GUIDE", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      variables = %{id: guide.id, thread: "GUIDE", communityId: community2.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      {:ok, found} = ORM.find(Guide, guide.id, preload: :communities)

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

    test "auth user can unmirror guide to a community", ~m(guide)a do
      passport_rules = %{"guide.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: guide.id, thread: "GUIDE", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      variables2 = %{id: guide.id, thread: "GUIDE", communityId: community2.id}
      rule_conn |> mutation_result(@mirror_article_query, variables2, "mirrorArticle")

      {:ok, found} = ORM.find(Guide, guide.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities

      passport_rules = %{"guide.community.unmirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@unmirror_article_query, variables, "unmirrorArticle")
      {:ok, found} = ORM.find(Guide, guide.id, preload: :communities)
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
    test "auth user can move guide to other community", ~m(guide)a do
      passport_rules = %{"guide.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: guide.id, thread: "GUIDE", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")
      {:ok, found} = ORM.find(Guide, guide.id, preload: [:original_community, :communities])
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities

      passport_rules = %{"guide.community.move" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      pre_original_community_id = found.original_community.id

      variables = %{id: guide.id, thread: "GUIDE", communityId: community2.id}
      rule_conn |> mutation_result(@move_article_query, variables, "moveArticle")
      {:ok, found} = ORM.find(Guide, guide.id, preload: [:original_community, :communities])
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert pre_original_community_id not in assoc_communities
      assert community2.id in assoc_communities
      assert community2.id == found.original_community_id

      assert found.original_community.id == community2.id
    end
  end
end
