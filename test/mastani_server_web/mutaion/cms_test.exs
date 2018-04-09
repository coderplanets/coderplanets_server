defmodule MastaniServer.Test.Mutation.CMSTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  # TODO remove
  alias MastaniServer.Statistics
  alias MastaniServer.CMS
  alias Helper.ORM

  setup do
    {:ok, community} = db_insert(:community)
    {:ok, tag} = db_insert(:tag, %{community: community})
    {:ok, user} = db_insert(:user)

    user_conn = mock_conn(:user, user)
    guest_conn = mock_conn(:guest)

    {:ok, ~m(user_conn guest_conn community user tag)a}
  end

  describe "[mutation cms tag]" do
    @create_tag_query """
    mutation($part: CmsPart!, $title: String!, $color: String!, $community: String!) {
      createTag(part: $part, title: $title, color: $color, community: $community) {
        id
        title
      }
    }
    """
    test "create tag with valid attrs, has default POST part", ~m(community)a do
      variables = mock_attrs(:tag, %{community: community.title})

      passport_rules = %{"cms" => %{community.title => %{"post.tag.create" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      created = rule_conn |> mutation_result(@create_tag_query, variables, "createTag")
      {:ok, found} = CMS.Tag |> ORM.find(created["id"])

      assert created["id"] == to_string(found.id)
      assert found.part == "post"
    end

    # TODO
    test "auth user create duplicate tag fails", ~m(community)a do
      variables = mock_attrs(:tag, %{community: community.title})
      passport_rules = %{"cms" => %{community.title => %{"post.tag.create" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      assert nil !== rule_conn |> mutation_result(@create_tag_query, variables, "createTag")

      assert rule_conn |> mutation_get_error?(@create_tag_query, variables)
    end

    test "unlogged user create tag fails", %{community: community, guest_conn: conn} do
      variables = mock_attrs(:tag, %{community: community.title})

      assert conn |> mutation_get_error?(@create_tag_query, variables)
    end

    @delete_tag_query """
    mutation($id: ID!, $community: String!){
      deleteTag(id: $id, community: $community) {
        id
      }
    }
    """
    @tag :wip
    test "auth user can delete tag", ~m(tag)a do
      passport_rules = %{"cms" => %{tag.community.title => %{"post.tag.delete" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      deleted =
        rule_conn
        |> mutation_result(
          @delete_tag_query,
          %{id: tag.id, community: tag.community.title},
          "deleteTag"
        )

      assert deleted["id"] == to_string(tag.id)
    end
  end

  describe "[mutation cms community]" do
    @create_community_query """
    mutation($title: String!, $desc: String!) {
      createCommunity(title: $title, desc: $desc) {
        id
        title
        desc
      }
    }
    """
    test "create community with valid attrs", %{user_conn: conn} do
      variables = mock_attrs(:community)
      created = conn |> mutation_result(@create_community_query, variables, "createCommunity")
      {:ok, found} = CMS.Community |> ORM.find(created["id"])

      assert created["id"] == to_string(found.id)
    end

    test "the user who create community should add contribute", %{user_conn: conn, user: user} do
      variables = mock_attrs(:community)
      created = conn |> mutation_result(@create_community_query, variables, "createCommunity")
      {:ok, found} = CMS.Community |> ORM.find(created["id"])

      {:ok, contribute} = ORM.find_by(Statistics.UserContributes, user_id: user.id)

      assert contribute.date == Timex.today()
      assert contribute.user_id == user.id
      assert contribute.count == 1

      assert created["id"] == to_string(found.id)
    end

    test "create duplicated community fails", %{community: community, user_conn: conn} do
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
      user_conn: conn
    } do
      deleted =
        conn |> mutation_result(@delete_community_query, %{id: community.id}, "deleteCommunity")

      assert deleted["id"] == to_string(community.id)
      assert {:error, _} = ORM.find(CMS.Community, community.id)
    end

    test "TODO(should be manager): delete non-exist community fails", %{user_conn: conn} do
      assert conn |> mutation_get_error?(@delete_community_query, %{id: 100_849_383})
    end
  end
end
