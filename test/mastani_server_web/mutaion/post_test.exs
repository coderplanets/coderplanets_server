defmodule MastaniServer.Test.Mutation.PostTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.AssertHelper

  alias MastaniServer.Repo
  alias MastaniServer.CMS
  alias Helper.ORM

  @valid_user mock_attrs(:user, %{nickname: "mydearxym"})
  @valid_post mock_attrs(:post)
  @valid_community mock_attrs(:community)
  @valid_community2 mock_attrs(:community)
  @valid_tag mock_attrs(:tag)
  @valid_tag2 mock_attrs(:tag)

  setup do
    db_insert(:user, @valid_user)
    {:ok, community} = db_insert(:community, @valid_community)
    {:ok, community2} = db_insert(:community, @valid_community2)

    {:ok, post} = db_insert(:post, %{title: "new post"})

    {:ok, tag} = db_insert(:tag, @valid_tag)
    {:ok, tag2} = db_insert(:tag, @valid_tag2)

    token = mock_jwt_token(nickname: @valid_user.nickname)

    conn =
      build_conn()
      |> put_req_header("authorization", token)
      |> put_req_header("content-type", "application/json")

    conn_without_token = build_conn()
    # |> put_req_header("content-type", "application/json")
    {:ok,
     conn: conn,
     conn_without_token: conn_without_token,
     post: post,
     community: community,
     community2: community2,
     tag: tag,
     tag2: tag2}
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
    test "create comment to a exsit post", %{post: post, conn: conn} do
      variables = %{type: "POST", id: post.id, body: "a test comment"}
      created = conn |> mutation_result(@create_comment_query, variables, "createComment")

      assert created["body"] == variables.body
    end

    @delete_comment_query """
    mutation($id: ID!) {
      deleteComment(id: $id) {
        id
      }
    }
    """
    test "delete a comment", %{post: post, conn: conn} do
      variables1 = %{type: "POST", id: post.id, body: "a test comment"}
      created = conn |> mutation_result(@create_comment_query, variables1, "createComment")
      assert created["body"] == variables1.body

      variables2 = %{id: created["id"]}

      deleted_comment =
        conn |> mutation_result(@delete_comment_query, variables2, "deleteComment")

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
    test "create post with valid attrs", %{conn: conn} do
      variables = @valid_post |> Map.merge(%{community: @valid_community.title})
      created = conn |> mutation_result(@create_post_query, variables, "createPost")
      post = Repo.get_by(CMS.Post, title: @valid_post.title)

      assert created["id"] == to_string(post.id)
    end

    @query """
    mutation ($id: ID!){
      deletePost(id: $id) {
        id
      }
    }
    """
    test "delete a post with valid auth", %{conn: conn, post: post} do
      deleted = conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert nil == Repo.get(CMS.Post, deleted["id"])
    end

    test "delete a post without login user fails", %{conn_without_token: conn, post: post} do
      assert conn |> mutation_get_error?(@query, %{id: post.id})
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
    test "update a post with valid data", %{conn: conn, post: post} do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: "updated body #{unique_num}"
      }

      updated_post = conn |> mutation_result(@query, variables, "updatePost")

      assert updated_post["title"] == variables.title
      assert updated_post["body"] == variables.body
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
    test "can set a tag to post", %{conn: conn, post: post, tag: tag} do
      variables = %{id: post.id, tagId: tag.id}
      conn |> mutation_result(@set_tag_query, variables, "setTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
    end

    test "can set multi tag to a post", %{conn: conn, post: post, tag: tag, tag2: tag2} do
      variables = %{id: post.id, tagId: tag.id}
      conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, tagId: tag2.id}
      conn |> mutation_result(@set_tag_query, variables2, "setTag")

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
    test "can unset tag from a post", %{conn: conn, post: post, tag: tag, tag2: tag2} do
      variables = %{id: post.id, tagId: tag.id}
      conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{id: post.id, tagId: tag2.id}
      conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags

      conn |> mutation_result(@unset_tag_query, variables, "unsetTag")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :tags)
      assoc_tags = found.tags |> Enum.map(& &1.id)

      assert tag.id not in assoc_tags
      assert tag2.id in assoc_tags
    end
  end

  describe "[mutation post community]" do
    # TODO
    @set_community_query """
    mutation($id: ID!, $communityId: ID!) {
      setCommunity(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "can set a community to post", %{conn: conn, post: post, community: community} do
      variables = %{id: post.id, communityId: community.id}
      conn |> mutation_result(@set_community_query, variables, "setCommunity")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
    end

    test "can set multi community to a post", %{
      conn: conn,
      post: post,
      community: community,
      community2: community2
    } do
      variables = %{id: post.id, communityId: community.id}
      conn |> mutation_result(@set_community_query, variables, "setCommunity")

      variables2 = %{id: post.id, communityId: community2.id}
      conn |> mutation_result(@set_community_query, variables2, "setCommunity")

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
    test "can unset community from a post", %{
      conn: conn,
      post: post,
      community: community,
      community2: community2
    } do
      variables = %{id: post.id, communityId: community.id}
      conn |> mutation_result(@set_community_query, variables, "setCommunity")

      variables2 = %{id: post.id, communityId: community2.id}
      conn |> mutation_result(@set_community_query, variables2, "setCommunity")

      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)

      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id in assoc_communities
      assert community2.id in assoc_communities

      conn |> mutation_result(@unset_community_query, variables, "unsetCommunity")
      {:ok, found} = ORM.find(CMS.Post, post.id, preload: :communities)
      assoc_communities = found.communities |> Enum.map(& &1.id)
      assert community.id not in assoc_communities
      assert community2.id in assoc_communities
    end
  end
end
