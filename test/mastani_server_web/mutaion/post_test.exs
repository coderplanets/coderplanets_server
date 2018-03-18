defmodule MastaniServer.Mutation.PostTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.AssertHelper

  alias MastaniServer.Repo
  alias MastaniServer.CMS

  @valid_user mock_attrs(:user, %{username: "mydearxym"})
  @valid_user2 mock_attrs(:user)
  @valid_post mock_attrs(:post)
  @valid_community mock_attrs(:community)

  setup do
    db_insert(:user, @valid_user)
    {:ok, user2} = db_insert(:user, @valid_user2)
    db_insert(:community, @valid_community)
    {:ok, post} = db_insert(:post, %{title: "new post"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer fake-token")
      |> put_req_header("content-type", "application/json")

    conn_without_token = build_conn()
    # |> put_req_header("content-type", "application/json")
    {:ok, conn: conn, conn_without_token: conn_without_token, post: post, user2: user2}
  end

  describe "MUTATION_POST_COMMENT" do
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
      result = conn |> mutation_result(@create_comment_query, variables, "createComment")

      assert result["body"] == variables.body
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
      result = conn |> mutation_result(@create_comment_query, variables1, "createComment")
      assert result["body"] == variables1.body

      variables2 = %{id: result["id"]}

      deleted_comment =
        conn |> mutation_result(@delete_comment_query, variables2, "deleteComment")

      assert deleted_comment["id"] == result["id"]

      assert nil == Repo.get(CMS.PostComment, deleted_comment["id"])
    end
  end

  describe "MUTATION_POST_CURD" do
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
      result = conn |> mutation_result(@create_post_query, variables, "createPost")
      post = Repo.get_by(CMS.Post, title: @valid_post.title)

      assert result["id"] == to_string(post.id)
    end

    @query """
    mutation ($id: ID!){
      deletePost(id: $id) {
        id
      }
    }
    """
    test "delete a post with valid auth", %{conn: conn, post: post} do
      deleted_post = conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted_post["id"] == to_string(post.id)
      assert nil == Repo.get(CMS.Post, deleted_post["id"])
    end

    test "delete a post without login user fails", %{conn_without_token: conn, post: post} do
      assert conn |> mutation_get_error?(@query, %{id: post.id})
    end

    # TODO related to token
    # test "delete a post with other user fails", %{conn: conn, post, post, user2: user2} do
    # assert conn |> mutation_get_error?(@query, %{id: post.id})
    # end

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
end
