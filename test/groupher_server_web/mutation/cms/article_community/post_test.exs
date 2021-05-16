defmodule GroupherServer.Test.Mutation.ArticleCommunity.Post do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    {:ok, ~m(user_conn guest_conn owner_conn community post)a}
  end

  describe "[mutation post tag]" do
    @set_tag_query """
    mutation($id: ID!, $thread: Thread, $tagId: ID! $communityId: ID!) {
      setTag(id: $id, thread: $thread, tagId: $tagId, communityId: $communityId) {
        id
        title
      }
    }
    """
    test "auth user can set a valid tag to post", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "post", community: community})

      passport_rules = %{community.title => %{"post.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: post.id, thread: "POST", tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
    end

    # TODO: should fix in auth layer
    # test "auth user set a other community tag to post fails", ~m(post)a do
    # {:ok, community} = db_insert(:community)
    # {:ok, tag} = db_insert(:tag, %{thread: "post"})

    # passport_rules = %{community.title => %{"post.tag.set" => true}}
    # rule_conn = simu_conn(:user, cms: passport_rules)

    # variables = %{id: post.id, tagId: tag.id, communityId: community.id}
    # assert rule_conn |> mutation_get_error?(@set_tag_query, variables)
    # end

    test "can set multi tag to a post", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "post", community: community})
      {:ok, tag2} = db_insert(:tag, %{thread: "post", community: community})

      passport_rules = %{community.title => %{"post.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: post.id, thread: "POST", tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, thread: "POST", tagId: tag2.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags
    end

    @unset_tag_query """
    mutation($id: ID!, $thread: Thread, $tagId: ID! $communityId: ID!) {
      unsetTag(id: $id, thread: $thread, tagId: $tagId, communityId: $communityId) {
        id
        title
      }
    }
    """
    test "can unset tag to a post", ~m(post)a do
      {:ok, community} = db_insert(:community)

      passport_rules = %{community.title => %{"post.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, tag} = db_insert(:tag, %{thread: "post", community: community})
      {:ok, tag2} = db_insert(:tag, %{thread: "post", community: community})

      variables = %{id: post.id, thread: "POST", tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, thread: "POST", tagId: tag2.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags

      passport_rules2 = %{community.title => %{"post.tag.unset" => true}}
      rule_conn2 = simu_conn(:user, cms: passport_rules2)

      rule_conn2 |> mutation_result(@unset_tag_query, variables, "unsetTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)
      assoc_tags = found.tags |> Enum.map(& &1.id)

      assert tag.id not in assoc_tags
      assert tag2.id in assoc_tags
    end
  end

  describe "[mirror/unmirror/move psot to/from community]" do
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
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

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

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

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

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities

      passport_rules = %{"post.community.unmirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@unmirror_article_query, variables, "unmirrorArticle")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)
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
    3

    test "auth user can move post to other community", ~m(post)a do
      passport_rules = %{"post.community.mirror" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: post.id, thread: "POST", communityId: community.id}
      rule_conn |> mutation_result(@mirror_article_query, variables, "mirrorArticle")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: [:original_community, :communities])
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities

      passport_rules = %{"post.community.move" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      pre_original_community_id = found.original_community.id

      variables = %{id: post.id, thread: "POST", communityId: community2.id}
      rule_conn |> mutation_result(@move_article_query, variables, "moveArticle")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: [:original_community, :communities])
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert pre_original_community_id not in assoc_communities
      assert community2.id in assoc_communities
      assert community2.id == found.original_community_id

      assert found.original_community.id == community2.id
    end
  end
end
