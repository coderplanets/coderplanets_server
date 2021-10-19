defmodule GroupherServer.Test.Mutation.ArticleCommunity.Post do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Post

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    {:ok, ~m(user_conn guest_conn owner_conn community post)a}
  end

  describe "[mirror/unmirror/move post to/from community]" do
    @mirror_article_query """
    mutation($id: ID!, $thread: Thread, $communityId: ID!) {
      mirrorArticle(id: $id, thread: $thread, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can mirror a post to other community", ~m(post)a do
      passport_rules = %{"post.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      variables = %{id: post.id, thread: "POST", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")
      {:ok, found} = ORM.find(Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
    end

    test "unauth user cannot mirror a post to a community", ~m(user_conn guest_conn post)a do
      {:ok, community} = db_insert(:community)
      variables = %{id: post.id, thread: "POST", communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:account_login))

      assert rule_conn
             |> mutation_get_error?(@mirror_article_query, variables, ecode(:passport))
    end

    test "auth user can mirror multi post to other communities", ~m(post)a do
      passport_rules = %{"post.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: post.id, thread: "POST", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      variables = %{id: post.id, thread: "POST", communityId: community2.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      {:ok, found} = ORM.find(Post, post.id, preload: :communities)

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

    test "auth user can unmirror post to a community", ~m(post)a do
      passport_rules = %{"post.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: post.id, thread: "POST", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")

      variables2 = %{id: post.id, thread: "POST", communityId: community2.id}
      rule_conn |> mutation_result(@mirror_article_query, variables2, "mirrorArticle")

      {:ok, found} = ORM.find(Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities

      passport_rules = %{"post.community.unmirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@unmirror_article_query, variables, "unmirrorArticle")
      {:ok, found} = ORM.find(Post, post.id, preload: :communities)
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id not in assoc_communities
      assert community2.id in assoc_communities
    end

    @mirror_to_home """
    mutation($id: ID!, $thread: Thread, $articleTags: [Id]) {
      mirrorToHome(id: $id, thread: $thread, articleTags: $articleTags) {
        id
      }
    }
    """

    test "auth user can mirror post home", ~m(post)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      variables = %{id: post.id, thread: "POST"}

      passport_rules = %{"homemirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@mirror_to_home, variables, "mirrorToHome")

      {:ok, post} = ORM.find(Post, post.id, preload: [:communities, :article_tags])

      assert exist_in?(home_community, post.communities)
    end

    @move_to_blackhole """
    mutation($id: ID!, $thread: Thread, $articleTags: [Id]) {
      moveToBlackhole(id: $id, thread: $thread, articleTags: $articleTags) {
        id
      }
    }
    """
    test "auth user can move post to blackhole", ~m(post)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      variables = %{id: post.id, thread: "POST"}

      passport_rules = %{"blackeye" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@move_to_blackhole, variables, "moveToBlackhole")

      {:ok, post} =
        ORM.find(Post, post.id, preload: [:original_community, :communities, :article_tags])

      assert post.original_community.id == blackhole_community.id
    end

    @move_article_query """
    mutation($id: ID!, $thread: Thread, $communityId: ID!, $articleTags: [Id]) {
      moveArticle(id: $id, thread: $thread, communityId: $communityId, articleTags: $articleTags) {
        id
      }
    }
    """
    test "auth user can move post to other community", ~m(post)a do
      passport_rules = %{"post.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: post.id, thread: "POST", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")
      {:ok, found} = ORM.find(Post, post.id, preload: [:original_community, :communities])
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities

      passport_rules = %{"post.community.move" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      pre_original_community_id = found.original_community.id

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, user} = db_insert(:user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :post, article_tag_attrs, user)

      variables = %{
        id: post.id,
        thread: "POST",
        communityId: community2.id,
        articleTags: [article_tag.id]
      }

      rule_conn |> mutation_result(@move_article_query, variables, "moveArticle")

      {:ok, found} =
        ORM.find(Post, post.id, preload: [:original_community, :communities, :article_tags])

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assoc_article_tags = found.article_tags |> Enum.map(& &1.id)

      assert pre_original_community_id not in assoc_communities
      assert community2.id in assoc_communities
      assert community2.id == found.original_community_id

      assert article_tag.id in assoc_article_tags

      assert found.original_community.id == community2.id
    end
  end
end
