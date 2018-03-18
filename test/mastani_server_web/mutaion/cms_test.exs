defmodule MastaniServer.Mutation.CMSTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.AssertHelper

  alias MastaniServer.Repo
  alias MastaniServer.CMS

  @valid_community mock_attrs(:community)
  @valid_user mock_attrs(:user, %{username: "mydearxym"})

  setup do
    {:ok, community} = db_insert(:community, @valid_community)
    {:ok, user} = db_insert(:user, @valid_user)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer fake-token")
      |> put_req_header("content-type", "application/json")

    conn_without_token = build_conn()
    {:ok, conn: conn, conn_without_token: conn_without_token, community: community, user: user}
  end

  describe "MUTATION_CMS_TAG" do
    @create_tag_query """
    mutation($type: CmsPart!, $title: String!, $color: String!, $community: String!) {
      createTag(type: $type, title: $title, color: $color, community: $community) {
        id
        title
      }
    }
    """
    test "create tag with valid attrs, has default POST type", %{community: community, conn: conn} do
      variables = mock_attrs(:tag, %{community: community.title})
      created_tag = conn |> mutation_result(@create_tag_query, variables, "createTag")
      tag = CMS.Tag |> Repo.get(created_tag["id"])

      assert created_tag["id"] == to_string(tag.id)
      assert tag.part == "post"
    end

    test "create duplicate tag fails", %{community: community, conn: conn} do
      variables = mock_attrs(:tag, %{community: community.title})
      conn |> mutation_result(@create_tag_query, variables, "createTag")

      assert conn |> mutation_get_error?(@create_tag_query, variables)
    end

    test "unlogged user create tag fails", %{community: community, conn_without_token: conn} do
      variables = mock_attrs(:tag, %{community: community.title})

      assert conn |> mutation_get_error?(@create_tag_query, variables)
    end
  end

  describe "MUTATION_CMS_COMMUNITY" do
    # TODO

  end
end
