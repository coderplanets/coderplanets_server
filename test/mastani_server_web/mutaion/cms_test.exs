defmodule MastaniServer.Test.Mutation.CMSTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper
  import ShortMaps

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

    test "auth user create duplicate tag fails", ~m(community)a do
      variables = mock_attrs(:tag, %{community: community.title})
      passport_rules = %{"cms" => %{community.title => %{"post.tag.create" => true}}}
      rule_conn = mock_conn(:user, passport_rules)

      assert nil !== rule_conn |> mutation_result(@create_tag_query, variables, "createTag")

      assert rule_conn |> mutation_get_error?(@create_tag_query, variables)
    end

    test "unauth user create tag fails", ~m(community user_conn guest_conn)a do
      variables = mock_attrs(:tag, %{community: community.title})
      rule_conn = mock_conn(:user, %{"cms" => %{"what.ever" => true}})

      assert user_conn |> mutation_get_error?(@create_tag_query, variables)
      assert guest_conn |> mutation_get_error?(@create_tag_query, variables)
      assert rule_conn |> mutation_get_error?(@create_tag_query, variables)
    end

    @delete_tag_query """
    mutation($id: ID!, $community: String!){
      deleteTag(id: $id, community: $community) {
        id
      }
    }
    """
    test "auth user can delete tag", ~m(tag)a do
      variables = %{id: tag.id, community: tag.community.title}

      rule_conn =
        mock_conn(:user, %{"cms" => %{tag.community.title => %{"post.tag.delete" => true}}})

      deleted = rule_conn |> mutation_result(@delete_tag_query, variables, "deleteTag")

      assert deleted["id"] == to_string(tag.id)
    end

    test "unauth user delete tag fails", ~m(tag user_conn guest_conn)a do
      variables = %{id: tag.id, community: tag.community.title}
      rule_conn = mock_conn(:user, %{"cms" => %{"what.ever" => true}})

      assert user_conn |> mutation_get_error?(@delete_tag_query, variables)
      assert guest_conn |> mutation_get_error?(@delete_tag_query, variables)
      assert rule_conn |> mutation_get_error?(@delete_tag_query, variables)
    end
  end

  describe "[mutation cms community]" do
    @create_community_query """
    mutation($title: String!, $desc: String!) {
      createCommunity(title: $title, desc: $desc) {
        id
        title
        desc
        author {
          id
        }
      }
    }
    """
    test "create community with valid attrs" do
      rule_conn = mock_conn(:user, %{"cms" => %{"community.create" => true}})
      variables = mock_attrs(:community)

      created =
        rule_conn |> mutation_result(@create_community_query, variables, "createCommunity")

      {:ok, found} = CMS.Community |> ORM.find(created["id"])
      assert created["id"] == to_string(found.id)
    end

    test "unauth user create community fails", ~m(user_conn guest_conn)a do
      variables = mock_attrs(:community)
      rule_conn = mock_conn(:user, %{"cms" => %{"what.ever" => true}})

      assert user_conn |> mutation_get_error?(@create_community_query, variables)
      assert guest_conn |> mutation_get_error?(@create_community_query, variables)
      assert rule_conn |> mutation_get_error?(@create_community_query, variables)
    end

    test "the user who create community should add contribute" do
      variables = mock_attrs(:community)
      rule_conn = mock_conn(:user, %{"cms" => %{"community.create" => true}})

      created =
        rule_conn |> mutation_result(@create_community_query, variables, "createCommunity")

      author = created["author"]

      {:ok, found} = CMS.Community |> ORM.find(created["id"])

      {:ok, contribute} = ORM.find_by(Statistics.UserContributes, user_id: author["id"])

      assert contribute.date == Timex.today()
      assert to_string(contribute.user_id) == author["id"]
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
    test "auth user can delete community", ~m(community)a do
      variables = %{id: community.id}
      rule_conn = mock_conn(:user, %{"cms" => %{"community.delete" => true}})

      deleted =
        rule_conn |> mutation_result(@delete_community_query, variables, "deleteCommunity")

      assert deleted["id"] == to_string(community.id)
      assert {:error, _} = ORM.find(CMS.Community, community.id)
    end

    test "unauth user delete community fails", ~m(user_conn guest_conn)a do
      variables = mock_attrs(:community)
      rule_conn = mock_conn(:user, %{"cms" => %{"what.ever" => true}})

      assert user_conn |> mutation_get_error?(@create_community_query, variables)
      assert guest_conn |> mutation_get_error?(@create_community_query, variables)
      assert rule_conn |> mutation_get_error?(@create_community_query, variables)
    end

    test "delete non-exist community fails" do
      rule_conn = mock_conn(:user, %{"cms" => %{"community.delete" => true}})
      assert rule_conn |> mutation_get_error?(@delete_community_query, %{id: 100_849_383})
    end
  end
end
