defmodule MastaniServer.Test.Mutation.PostTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  alias MastaniServer.Repo
  # alias MastaniServer.Accounts.User
  alias MastaniServer.CMS
  alias Helper.ORM

  setup do
    {:ok, post} = db_insert(:post)

    guest_conn = mock_conn(:guest)
    user_conn = mock_conn(:user)
    owner_conn = mock_conn(:owner, post)

    {:ok, guest_conn: guest_conn, user_conn: user_conn, owner_conn: owner_conn, post: post}
  end

  describe "[mutation post comment]" do
    @create_comment_query """
    mutation($type: CmsPart!, $id: ID!, $body: String!) {
      createComment(type: $type,id: $id, body: $body) {
        id
        body
      }
    }
    """
    # test "create comment to a exsit post", %{post: post, user_conn: user_conn} do
    test "create comment to a exsit post", ~m(post user_conn)a do
      variables = %{type: "POST", id: post.id, body: "a test comment"}
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
      variables1 = %{type: "POST", id: post.id, body: "a test comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables1, "createComment")
      assert created["body"] == variables1.body

      variables2 = %{id: created["id"]}

      deleted_comment =
        user_conn |> mutation_result(@delete_comment_query, variables2, "deleteComment")

      assert deleted_comment["id"] == created["id"]

      assert nil == Repo.get(CMS.PostComment, deleted_comment["id"])
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
      {:ok, post} = ORM.find_by(CMS.Post, title: post_attr.title)

      assert {:ok, _} = ORM.find_by(CMS.Author, user_id: user.id)

      assert created["id"] == to_string(post.id)
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
      assert nil == Repo.get(CMS.Post, deleted["id"])
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

    test "login user with wrong passport delete a post fails", ~m(post)a do
      # post_communities_0 = post.communities |> List.first() |> Map.get(:title)
      # IO.inspect(post_communities_0, label: "hello")
      # CMS.stamp_passport(%User{id: user.id}, community_rules)

      passport_rules = %{"xxx" => %{"x.y.z": true}}
      conn = mock_conn(:user, passport_rules)

      assert conn |> mutation_get_error?(@query, %{id: post.id})
    end

    test "login user without passport delete a post fails", ~m(user_conn post)a do
      assert user_conn |> mutation_get_error?(@query, %{id: post.id})
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

    test "login user without passport update  post fails", ~m(user_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      assert user_conn |> mutation_get_error?(@query, variables)
    end
  end

  describe "[mutation post tag]" do
    @set_tag_query """
    mutation($id: ID!, $tagId: ID!) {
      setTag(id: $id, tagId: $tagId) {
        id
        title
      }
    }
    """
    test "can set a tag to post", ~m(user_conn post)a do
      {:ok, tag} = db_insert(:tag)
      variables = %{id: post.id, tagId: tag.id}
      user_conn |> mutation_result(@set_tag_query, variables, "setTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
    end

    test "can set multi tag to a post", ~m(user_conn post)a do
      {:ok, tag} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      variables = %{id: post.id, tagId: tag.id}
      user_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, tagId: tag2.id}
      user_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags
    end

    @unset_tag_query """
    mutation($id: ID!, $tagId: ID!) {
      unsetTag(id: $id, tagId: $tagId) {
        id
        title
      }
    }
    """
    test "can unset tag from a post", ~m(user_conn post)a do
      {:ok, tag} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      variables = %{id: post.id, tagId: tag.id}
      user_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, tagId: tag2.id}
      user_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags

      user_conn |> mutation_result(@unset_tag_query, variables, "unsetTag")
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

    test "other user set a community to post fails", ~m(user_conn post)a do
      {:ok, community} = db_insert(:community)
      variables = %{id: post.id, community: community.title}
      user_conn |> mutation_get_error?(@set_community_query, variables)
    end

    test "guest user set a community to post fails", ~m(guest_conn post)a do
      {:ok, community} = db_insert(:community)
      variables = %{id: post.id, community: community.title}
      guest_conn |> mutation_get_error?(@set_community_query, variables)
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
