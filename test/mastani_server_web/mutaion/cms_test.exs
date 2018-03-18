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
      created = conn |> mutation_result(@create_tag_query, variables, "createTag")
      found = CMS.Tag |> Repo.get(created["id"])

      assert created["id"] == to_string(found.id)
      assert found.part == "post"
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

    @delete_tag_query """
    mutation($id: ID!){
      deleteTag(id: $id) {
        id
      }
    }
    """
    test "TODO(should be manager): delete tag by login user", %{community: community, conn: conn} do
      variables = mock_attrs(:tag, %{community: community.title})
      created = conn |> mutation_result(@create_tag_query, variables, "createTag")
      found = CMS.Tag |> Repo.get(created["id"])
      assert created["id"] == to_string(found.id)

      deleted = conn |> mutation_result(@delete_tag_query, %{id: created["id"]}, "deleteTag")

      assert deleted["id"] == created["id"]
    end

    test "TODO(should be manager): delete non-exist tag fails", %{conn: conn} do
      assert conn |> mutation_get_error?(@delete_tag_query, %{id: 100_849_383})
    end
  end

  describe "MUTATION_CMS_COMMUNITY" do
    @create_community_query """
    mutation($title: String!, $desc: String!) {
      createCommunity(title: $title, desc: $desc) {
        id
        title
        desc
      }
    }
    """
    test "create community with valid attrs", %{conn: conn} do
      variables = mock_attrs(:community)
      created = conn |> mutation_result(@create_community_query, variables, "createCommunity")
      found = CMS.Community |> Repo.get(created["id"])

      assert created["id"] == to_string(found.id)
    end

    test "create duplicated community fails", %{community: community, conn: conn} do
      variables = mock_attrs(:community, %{title: community.title, desc: community.desc})
      assert conn |> mutation_get_error?(@create_community_query, variables)
    end

    @delete_community_query """
    mutation($id: ID!){
      deleteCommunity(id: $id) {
        id
      }
    }
    """
    test "TODO(should be manager): delete community by login user", %{
      community: community,
      conn: conn
    } do
      deleted =
        conn |> mutation_result(@delete_community_query, %{id: community.id}, "deleteCommunity")

      assert deleted["id"] == to_string(community.id)
      assert nil == Repo.get(CMS.Community, community.id)
    end

    test "TODO(should be manager): delete non-exist community fails", %{conn: conn} do
      assert conn |> mutation_get_error?(@delete_community_query, %{id: 100_849_383})
    end
  end
end
