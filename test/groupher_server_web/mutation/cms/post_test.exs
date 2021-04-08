defmodule GroupherServer.Test.Mutation.Post do
  use GroupherServer.TestTools

  alias Helper.{ORM, Utils}
  alias GroupherServer.{CMS, Delivery}

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    {:ok, ~m(user_conn guest_conn owner_conn community post)a}
  end

  describe "[mutation post curd]" do
    @create_post_query """
    mutation(
      $title: String!
      $body: String!
      $digest: String!
      $length: Int!
      $communityId: ID!
      $tags: [Ids]
      $mentionUsers: [Ids]
      $topic: String
    ) {
      createPost(
        title: $title
        body: $body
        digest: $digest
        length: $length
        communityId: $communityId
        tags: $tags
        mentionUsers: $mentionUsers
        topic: $topic
      ) {
        title
        body
        id
        origialCommunity {
          id
        }
      }
    }
    """
    test "create post with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables = post_attr |> Map.merge(%{communityId: community.id})
      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(CMS.Post, created["id"])

      assert created["id"] == to_string(post.id)
      assert created["origialCommunity"]["id"] == to_string(community.id)

      assert {:ok, _} = ORM.find_by(CMS.Author, user_id: user.id)
    end

    test "create post should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post, %{body: assert_v(:xss_string)})

      variables = post_attr |> Map.merge(%{communityId: community.id})
      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(CMS.Post, created["id"])

      assert post.body == assert_v(:xss_safe_string)
    end

    # NOTE: this test is IMPORTANT, cause json_codec: Jason in router will cause
    # server crash when GraphQL parse error
    test "create post with missing non_null field should get 200 error" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)
      variables = post_attr |> Map.merge(%{communityId: community.id}) |> Map.delete(:title)

      assert user_conn |> mutation_get_error?(@create_post_query, variables)
    end

    test "can create post with tags" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      post_attr = mock_attrs(:post)

      variables =
        post_attr
        |> Map.merge(%{communityId: community.id})
        |> Map.merge(%{tags: [%{id: tag1.id}, %{id: tag2.id}]})

      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(CMS.Post, created["id"], preload: :tags)

      assert post.tags |> Enum.any?(&(&1.id == tag1.id))
      assert post.tags |> Enum.any?(&(&1.id == tag2.id))
    end

    test "can create post with mentionUsers" do
      {:ok, user} = db_insert(:user)
      {:ok, user2} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables =
        post_attr
        |> Map.merge(%{communityId: community.id})
        |> Map.merge(%{mentionUsers: [%{id: user2.id}]})

      filter = %{page: 1, size: 20, read: false}
      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)
      assert mentions.total_count == 0

      _created = user_conn |> mutation_result(@create_post_query, variables, "createPost")

      {:ok, mentions} = Delivery.fetch_mentions(user2, filter)

      assert mentions.total_count == 1
      assert mentions.entries |> List.first() |> Map.get(:community) !== nil
    end

    @query """
    mutation($id: ID!){
      deletePost(id: $id) {
        id
      }
    }
    """
    test "delete a post by post's owner", ~m(owner_conn post)a do
      deleted = owner_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert {:error, _} = ORM.find(CMS.Post, deleted["id"])
    end

    test "can delete a post by auth user", ~m(post)a do
      belongs_community_title = post.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"post.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert {:error, _} = ORM.find(CMS.Post, deleted["id"])
    end

    test "delete a post without login user fails", ~m(guest_conn post)a do
      assert guest_conn |> mutation_get_error?(@query, %{id: post.id}, ecode(:account_login))
    end

    test "login user with auth passport delete a post", ~m(post)a do
      post_communities_0 = post.communities |> List.first() |> Map.get(:title)
      passport_rules = %{post_communities_0 => %{"post.delete" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: post.id})

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
    end

    test "unauth user delete post fails", ~m(user_conn guest_conn post)a do
      variables = %{id: post.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $copyRight: String, $tags: [Ids]){
      updatePost(id: $id, title: $title, body: $body, copyRight: $copyRight, tags: $tags) {
        id
        title
        body
        copyRight
        meta {
          isEdited
        }
      }
    }
    """
    test "update a post without login user fails", ~m(guest_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "can update post with tags", ~m(owner_conn post)a do
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        tags: [%{id: tag1.id}, %{id: tag2.id}]
      }

      updated = owner_conn |> mutation_result(@query, variables, "updatePost")
      {:ok, post} = ORM.find(CMS.Post, updated["id"], preload: :tags)
      tag_ids = post.tags |> Utils.pick_by(:id)

      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
    end

    test "can update post with refined tag", ~m(owner_conn post)a do
      {:ok, tag_refined} = db_insert(:tag, %{title: "refined"})
      {:ok, tag2} = db_insert(:tag)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        tags: [%{id: tag_refined.id}, %{id: tag2.id}]
      }

      updated = owner_conn |> mutation_result(@query, variables, "updatePost")
      {:ok, post} = ORM.find(CMS.Post, updated["id"], preload: :tags)
      tag_ids = post.tags |> Utils.pick_by(:id)

      assert tag_refined.id not in tag_ids
      assert tag2.id in tag_ids
    end

    test "post can be update by owner", ~m(owner_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}",
        copyRight: "translate"
      }

      updated_post = owner_conn |> mutation_result(@query, variables, "updatePost")

      assert updated_post["title"] == variables.title
      assert updated_post["body"] == variables.body
      assert updated_post["copyRight"] == variables.copyRight
    end

    @tag :wip
    test "update post with valid attrs should have is_edited meta info update",
         ~m(owner_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      updated_post = owner_conn |> mutation_result(@query, variables, "updatePost")

      assert true == updated_post["meta"]["isEdited"]
    end

    test "login user with auth passport update a post", ~m(post)a do
      belongs_community_title = post.communities |> List.first() |> Map.get(:title)

      passport_rules = %{belongs_community_title => %{"post.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: post.id})
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      updated_post = rule_conn |> mutation_result(@query, variables, "updatePost")

      assert updated_post["id"] == to_string(post.id)
    end

    test "unauth user update post fails", ~m(user_conn guest_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end

  describe "[mutation post tag]" do
    @set_tag_query """
    mutation($id: ID!, $tagId: ID! $communityId: ID!) {
      setTag(id: $id, tagId: $tagId, communityId: $communityId) {
        id
        title
      }
    }
    """
    @set_refined_tag_query """
    mutation($communityId: ID!, $thread: CmsThread, $topic: String, $id: ID!) {
      setRefinedTag(communityId: $communityId, thread: $thread, topic: $topic, id: $id) {
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

      variables = %{id: post.id, tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
    end

    test "can not set refined tag to post", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "post", community: community, title: "refined"})

      passport_rules = %{community.title => %{"post.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: post.id, tagId: tag.id}

      assert rule_conn |> mutation_get_error?(@set_tag_query, variables)
    end

    test "auth user can set refined tag to post", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "post", community: community, title: "refined"})

      passport_rules = %{community.title => %{"post.refinedtag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: post.id, communityId: community.id}
      rule_conn |> mutation_result(@set_refined_tag_query, variables, "setRefinedTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
    end

    test "auth user can set refined tag to post of spec topic", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, user} = db_insert(:user)

      tag_attrs =
        mock_attrs(:tag, %{thread: "post", community: community, title: "refined", topic: "tech"})

      {:ok, tag} = CMS.create_tag(community, :post, tag_attrs, user)

      passport_rules = %{community.title => %{"post.refinedtag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: post.id, communityId: community.id, topic: "tech"}
      rule_conn |> mutation_result(@set_refined_tag_query, variables, "setRefinedTag")
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

      variables = %{id: post.id, tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, tagId: tag2.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags
    end

    @unset_tag_query """
    mutation($id: ID!, $tagId: ID!, $communityId: ID!) {
      unsetTag(id: $id, tagId: $tagId, communityId: $communityId) {
        id
        title
      }
    }
    """
    @unset_refined_tag_query """
    mutation($communityId: ID!, $thread: CmsThread, $topic: String, $id: ID!) {
      unsetRefinedTag(communityId: $communityId, thread: $thread, topic: $topic, id: $id) {
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

      variables = %{id: post.id, tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, tagId: tag2.id, communityId: community.id}
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

    test "can unset refined tag to a post", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "post", community: community, title: "refined"})

      passport_rules = %{community.title => %{"post.refinedtag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: post.id, communityId: community.id}
      rule_conn |> mutation_result(@set_refined_tag_query, variables, "setRefinedTag")

      variables = %{id: post.id, communityId: community.id}
      rule_conn |> mutation_result(@unset_refined_tag_query, variables, "unsetRefinedTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id not in assoc_tags
    end

    test "can unset refined tag to a post of spec topic", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, user} = db_insert(:user)

      tag_attrs =
        mock_attrs(:tag, %{thread: "post", community: community, title: "refined", topic: "tech"})

      {:ok, tag} = CMS.create_tag(community, :post, tag_attrs, user)

      passport_rules = %{community.title => %{"post.refinedtag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: post.id, communityId: community.id, topic: "tech"}
      rule_conn |> mutation_result(@set_refined_tag_query, variables, "setRefinedTag")

      variables = %{id: post.id, communityId: community.id, topic: "tech"}
      rule_conn |> mutation_result(@unset_refined_tag_query, variables, "unsetRefinedTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id not in assoc_tags
    end
  end

  describe "[mutation post community]" do
    @set_community_query """
    mutation($id: ID!, $communityId: ID!) {
      setCommunity(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can set a community to post", ~m(post)a do
      passport_rules = %{"post.community.set" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      variables = %{id: post.id, communityId: community.id}
      rule_conn |> mutation_result(@set_community_query, variables, "setCommunity")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
    end

    test "unauth user set a community to post fails", ~m(user_conn guest_conn post)a do
      {:ok, community} = db_insert(:community)
      variables = %{id: post.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@set_community_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@set_community_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@set_community_query, variables, ecode(:passport))
    end

    test "auth user can set multi community to a post", ~m(post)a do
      passport_rules = %{"post.community.set" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: post.id, communityId: community.id}
      rule_conn |> mutation_result(@set_community_query, variables, "setCommunity")

      variables = %{id: post.id, communityId: community2.id}
      rule_conn |> mutation_result(@set_community_query, variables, "setCommunity")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities
    end

    @unset_community_query """
    mutation($id: ID!, $communityId: ID!) {
      unsetCommunity(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can unset community from a post", ~m(post)a do
      passport_rules = %{"post.community.set" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: post.id, communityId: community.id}
      rule_conn |> mutation_result(@set_community_query, variables, "setCommunity")

      variables2 = %{id: post.id, communityId: community2.id}
      rule_conn |> mutation_result(@set_community_query, variables2, "setCommunity")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities

      passport_rules = %{"post.community.unset" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@unset_community_query, variables, "unsetCommunity")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id not in assoc_communities
      assert community2.id in assoc_communities
    end
  end

  describe "[mutation post comment]" do
    @create_comment_query """
    mutation($community: String!, $thread: CmsThread!, $id: ID!, $body: String!) {
      createComment(community: $community, thread: $thread,id: $id, body: $body) {
        id
        body
      }
    }
    """
    test "create comment to a exsit post", ~m(post user_conn community)a do
      variables = %{community: community.raw, thread: "POST", id: post.id, body: "a test comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      assert created["body"] == variables.body
    end

    @update_comment_query """
    mutation($thread: CmsThread!, $id: ID!, $body: String!) {
      updateComment(thread: $thread,id: $id, body: $body) {
        id
        body
      }
    }
    """
    test "can update a exsit comment", ~m(post user_conn community)a do
      variables = %{community: community.raw, thread: "POST", id: post.id, body: "a test comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      variables = %{thread: "POST", id: created["id"], body: "updated body"}
      updated = user_conn |> mutation_result(@update_comment_query, variables, "updateComment")

      assert updated["body"] == "updated body"
    end

    @delete_comment_query """
    mutation($id: ID!) {
      deleteComment(id: $id) {
        id
      }
    }
    """
    test "delete a comment", ~m(post user_conn community)a do
      variables1 = %{
        community: community.raw,
        thread: "POST",
        id: post.id,
        body: "a test comment"
      }

      created = user_conn |> mutation_result(@create_comment_query, variables1, "createComment")
      assert created["body"] == variables1.body

      variables2 = %{id: created["id"]}

      deleted = user_conn |> mutation_result(@delete_comment_query, variables2, "deleteComment")

      assert deleted["id"] == created["id"]

      assert {:error, _} = ORM.find(CMS.PostComment, deleted["id"])
    end
  end
end
