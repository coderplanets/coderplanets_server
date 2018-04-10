defmodule MastaniServer.Test.Mutation.PostTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  # alias MastaniServer.Accounts.User
  alias MastaniServer.CMS
  alias Helper.ORM

  setup do
    {:ok, post} = db_insert(:post)

    guest_conn = mock_conn(:guest)
    user_conn = mock_conn(:user)
    owner_conn = mock_conn(:owner, post)

    {:ok, ~m(user_conn guest_conn owner_conn post)a}
  end

  describe "[mutation post comment]" do
    @create_comment_query """
    mutation($part: CmsPart!, $id: ID!, $body: String!) {
      createComment(part: $part,id: $id, body: $body) {
        id
        body
      }
    }
    """
    test "create comment to a exsit post", ~m(post user_conn)a do
      variables = %{part: "POST", id: post.id, body: "a test comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      assert created["body"] == variables.body
    end

    @delete_comment_query """
    mutation($id: ID!) {
      deleteComment(id: $id) {
        id
      }
    }
    """
    test "delete a comment", ~m(post user_conn)a do
      variables1 = %{part: "POST", id: post.id, body: "a test comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables1, "createComment")
      assert created["body"] == variables1.body

      variables2 = %{id: created["id"]}

      deleted_comment =
        user_conn |> mutation_result(@delete_comment_query, variables2, "deleteComment")

      assert deleted_comment["id"] == created["id"]

      assert {:error, _} = ORM.find(CMS.PostComment, deleted_comment["id"])
    end
  end

  describe "[mutation post curd]" do
    @create_post_query """
    mutation ($title: String!, $body: String!, $digest: String!, $length: Int!, $community: String!){
      createPost(title: $title, body: $body, digest: $digest, length: $length, community: $community) {
        title
        body
        id
      }
    }
    """
    test "create post with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = mock_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables = post_attr |> Map.merge(%{community: community.title})
      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(CMS.Post, created["id"])

      assert created["id"] == to_string(post.id)
      assert {:ok, _} = ORM.find_by(CMS.Author, user_id: user.id)
    end

    @query """
    mutation ($id: ID!){
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

    test "delete a post without login user fails", ~m(guest_conn post)a do
      assert guest_conn |> mutation_get_error?(@query, %{id: post.id})
    end

    test "login user with auth passport delete a post", ~m(post)a do
      post_communities_0 = post.communities |> List.first() |> Map.get(:title)
      passport_rules = %{"cms" => %{post_communities_0 => %{"post.article.delete" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: post.id})

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
    end

    test "unauth user delete post fails", ~m(user_conn guest_conn post)a do
      variables = %{id: post.id}
      rule_conn = mock_conn(:user, %{"cms" => %{"what.ever" => true}})

      assert user_conn |> mutation_get_error?(@query, variables)
      assert guest_conn |> mutation_get_error?(@query, variables)
      assert rule_conn |> mutation_get_error?(@query, variables)
    end

    @query """
    mutation ($id: ID!, $title: String, $body: String){
      updatePost(id: $id, title: $title, body: $body) {
        id
        title
        body
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

      assert guest_conn |> mutation_get_error?(@query, variables)
    end

    test "update a post with by post's owner", ~m(owner_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      updated_post = owner_conn |> mutation_result(@query, variables, "updatePost")

      assert updated_post["title"] == variables.title
      assert updated_post["body"] == variables.body
    end

    test "login user with auth passport update a post", ~m(post)a do
      post_communities_0 = post.communities |> List.first() |> Map.get(:title)
      passport_rules = %{"cms" => %{post_communities_0 => %{"post.article.edit" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

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

      rule_conn = mock_conn(:user, %{"cms" => %{"what.ever" => true}})

      assert user_conn |> mutation_get_error?(@query, variables)
      assert guest_conn |> mutation_get_error?(@query, variables)
      assert rule_conn |> mutation_get_error?(@query, variables)
    end
  end

  describe "[mutation post tag]" do
    @set_tag_query """
    mutation($id: ID!, $tagId: ID! $community: String!) {
      setTag(id: $id, tagId: $tagId, community: $community) {
        id
        title
      }
    }
    """
    test "auth user can set a valid tag to post", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{community: community})
      # {:ok, tag} = db_insert(:tag)

      passport_rules = %{"cms" => %{community.title => %{"post.tag.set" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      variables = %{id: post.id, tagId: tag.id, community: community.title}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
    end

    test "auth user set a invalid tag to post fails", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag)

      passport_rules = %{"cms" => %{community.title => %{"post.tag.set" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      variables = %{id: post.id, tagId: tag.id, community: community.title}
      assert rule_conn |> mutation_get_error?(@set_tag_query, variables)
    end

    test "can set multi tag to a post", ~m(post)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{community: community})
      {:ok, tag2} = db_insert(:tag, %{community: community})

      passport_rules = %{"cms" => %{community.title => %{"post.tag.set" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      variables = %{id: post.id, tagId: tag.id, community: community.title}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, tagId: tag2.id, community: community.title}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags
    end

    @unset_tag_query """
    mutation($id: ID!, $tagId: ID!, $community: String!) {
      unsetTag(id: $id, tagId: $tagId, community: $community) {
        id
        title
      }
    }
    """
    test "can unset tag from a post", ~m(post)a do
      {:ok, community} = db_insert(:community)

      passport_rules = %{"cms" => %{community.title => %{"post.tag.set" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      {:ok, tag} = db_insert(:tag, %{community: community})
      {:ok, tag2} = db_insert(:tag, %{community: community})

      variables = %{id: post.id, tagId: tag.id, community: community.title}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, tagId: tag2.id, community: community.title}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags

      rule_conn |> mutation_result(@unset_tag_query, variables, "unsetTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)
      assoc_tags = found.tags |> Enum.map(& &1.id)

      assert tag.id not in assoc_tags
      assert tag2.id in assoc_tags
    end
  end

  describe "[mutation post community]" do
    # TODO
    @set_community_query """
    mutation($id: ID!, $community: String!) {
      setCommunity(id: $id, community: $community) {
        id
      }
    }
    """
    test "auth user can set a community to post", ~m(post)a do
      passport_rules = %{"cms" => %{"post.community.set" => true}}
      rule_conn = mock_conn(:user, passport_rules)

      {:ok, community} = db_insert(:community)
      variables = %{id: post.id, community: community.title}
      rule_conn |> mutation_result(@set_community_query, variables, "setCommunity")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
    end

    test "unauth user set a community to post fails", ~m(user_conn guest_conn post)a do
      {:ok, community} = db_insert(:community)
      variables = %{id: post.id, community: community.title}
      rule_conn = mock_conn(:user, %{"cms" => %{"what.ever" => true}})

      assert user_conn |> mutation_get_error?(@set_community_query, variables)
      assert guest_conn |> mutation_get_error?(@set_community_query, variables)
      assert rule_conn |> mutation_get_error?(@set_community_query, variables)
    end

    test "auth user can set multi community to a post", ~m(post)a do
      passport_rules = %{"cms" => %{"post.community.set" => true}}
      rule_conn = mock_conn(:user, passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: post.id, community: community.title}
      rule_conn |> mutation_result(@set_community_query, variables, "setCommunity")

      variables2 = %{id: post.id, community: community2.title}
      rule_conn |> mutation_result(@set_community_query, variables2, "setCommunity")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities
    end

    @unset_community_query """
    mutation($id: ID!, $community: String!) {
      unsetCommunity(id: $id, community: $community) {
        id
      }
    }
    """
    test "auth user can unset community from a post", ~m(post)a do
      passport_rules = %{"cms" => %{"post.community.set" => true}}
      rule_conn = mock_conn(:user, passport_rules)

      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      variables = %{id: post.id, community: community.title}
      rule_conn |> mutation_result(@set_community_query, variables, "setCommunity")

      variables2 = %{id: post.id, community: community2.title}
      rule_conn |> mutation_result(@set_community_query, variables2, "setCommunity")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities

      rule_conn |> mutation_result(@unset_community_query, variables, "unsetCommunity")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id not in assoc_communities
      assert community2.id in assoc_communities
    end
  end
end
