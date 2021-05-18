defmodule GroupherServer.Test.Mutation.ArticleTags.PostTag do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    tag_attrs = mock_attrs(:tag)
    tag_attrs2 = mock_attrs(:tag)

    {:ok, ~m(user_conn guest_conn owner_conn community post tag_attrs tag_attrs2 user)a}
  end

  describe "[mutation post tag]" do
    @set_tag_query """
    mutation($id: ID!, $thread: Thread, $articleTagId: ID!, $communityId: ID!) {
      setArticleTag(id: $id, thread: $thread, articleTagId: $articleTagId, communityId: $communityId) {
        id
      }
    }
    """
    @tag :wip2
    test "auth user can set a valid tag to post", ~m(community post tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, tag_attrs, user)

      passport_rules = %{community.title => %{"post.article_tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{
        id: post.id,
        thread: "POST",
        articleTagId: article_tag.id,
        communityId: community.id
      }

      rule_conn |> mutation_result(@set_tag_query, variables, "setArticleTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :article_tags)

      assoc_tags = found.article_tags |> Enum.map(& &1.id)
      assert article_tag.id in assoc_tags
    end

    test "can set multi tag to a post", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "post", community: community})
      {:ok, tag2} = db_insert(:tag, %{thread: "post", community: community})

      passport_rules = %{community.title => %{"post.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: post.id, thread: "POST", tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setArticleTag")

      variables2 = %{id: post.id, thread: "POST", tagId: tag2.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setArticleTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.article_tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags
    end

    @unset_tag_query """
    mutation($id: ID!, $thread: Thread, $tagId: ID!, $communityId: ID!) {
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
      rule_conn |> mutation_result(@set_tag_query, variables, "setArticleTag")

      variables2 = %{id: post.id, thread: "POST", tagId: tag2.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setArticleTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.article_tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags

      passport_rules2 = %{community.title => %{"post.tag.unset" => true}}
      rule_conn2 = simu_conn(:user, cms: passport_rules2)

      rule_conn2 |> mutation_result(@unset_tag_query, variables, "unsetTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)
      assoc_tags = found.article_tags |> Enum.map(& &1.id)

      assert tag.id not in assoc_tags
      assert tag2.id in assoc_tags
    end
  end
end
