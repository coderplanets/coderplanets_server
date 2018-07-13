defmodule MastaniServer.Test.Query.AccountTest do
  use MastaniServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias MastaniServer.CMS
  alias CMS.Community

  @default_subscribed_communities get_config(:general, :default_subscribed_communities)

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user)a}
  end

  describe "[account test]" do
    @query """
    query($id: ID!) {
      user(id: $id) {
        id
        nickname
        bio
        cmsPassport
        cmsPassportString
      }
    }
    """
    test "guest user can get specific user by user's id", ~m(guest_conn user)a do
      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "user")
      assert results["id"] == to_string(user.id)
      assert results["nickname"] == user.nickname
    end

    @valid_rules %{
      "javascript" => %{
        "post.article.delete" => true,
        "post.tag.edit" => true
      }
    }

    test "login user can get own cms_passport and cms_passport_string", ~m(user)a do
      user_conn = simu_conn(:user, user)

      {:ok, _} = CMS.stamp_passport(@valid_rules, user)

      variables = %{id: user.id}
      results = user_conn |> query_result(@query, variables, "user")

      assert Map.equal?(results["cmsPassport"], @valid_rules)
      assert Map.equal?(Jason.decode!(results["cmsPassportString"]), @valid_rules)
    end

    test "login user can get nil if cms_passport not exsit", ~m(user)a do
      user_conn = simu_conn(:user, user)

      variables = %{id: user.id}
      results = user_conn |> query_result(@query, variables, "user")

      assert nil == results["cmsPassport"]
      assert nil == results["cmsPassportString"]
    end

    @query """
    query($filter: PagedUsersFilter!) {
      pagedUsers(filter: $filter) {
        entries {
          id
          nickname
          bio
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "guest user can get paged users", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 10}}

      results = guest_conn |> query_result(@query, variables, "pagedUsers")
      assert results |> is_valid_pagination?()
    end
  end

  describe "[account passport] test" do
    @query """
    query {
      allPassportRulesString {
        cms
      }
    }
    """
    test "can get all cms rules with valid structure", ~m(user)a do
      user_conn = simu_conn(:user, user)
      variables = %{}
      results = user_conn |> query_result(@query, variables, "allPassportRulesString")

      assert results |> Map.has_key?("cms")
      cms_rules = results["cms"]
      assert cms_rules |> Map.has_key?("general")
      assert cms_rules |> Map.has_key?("community")
    end
  end

  describe "[account subscrube]" do
    @query """
    query($id: ID!) {
      user(id: $id) {
        id
        nickname
        subscribedCommunitiesCount
        subscribedCommunities {
          id
          title
        }
      }
    }
    """
    test "gest user can get subscrubed community list and count", ~m(guest_conn user)a do
      variables = %{id: user.id}
      {:ok, communities} = db_insert_multi(:community, inner_page_size())

      Enum.each(
        communities,
        &CMS.subscribe_community(%Community{id: &1.id}, user)
      )

      results = guest_conn |> query_result(@query, variables, "user")
      subscribed_communities = results["subscribedCommunities"]
      subscribed_communities_count = results["subscribedCommunitiesCount"]
      [community_1, community_2, community_3, community_x] = communities |> firstn_and_last(3)

      assert subscribed_communities |> Enum.any?(&(&1["id"] == to_string(community_1.id)))
      assert subscribed_communities |> Enum.any?(&(&1["id"] == to_string(community_2.id)))
      assert subscribed_communities |> Enum.any?(&(&1["id"] == to_string(community_3.id)))
      assert subscribed_communities |> Enum.any?(&(&1["id"] == to_string(community_x.id)))
      assert subscribed_communities_count == inner_page_size()
    end

    test "gest user can get subscrubed communities count of 20 at most", ~m(guest_conn user)a do
      variables = %{id: user.id}
      {:ok, communities} = db_insert_multi(:community, inner_page_size() + 1)

      Enum.each(
        communities,
        &CMS.subscribe_community(%Community{id: &1.id}, user)
      )

      results = guest_conn |> query_result(@query, variables, "user")
      subscribed_communities = results["subscribedCommunities"]

      assert length(subscribed_communities) == inner_page_size()
    end

    @query """
    query($filter: PagedFilter!) {
      subscribedCommunities(filter: $filter) {
        entries {
          title
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "gest user can get paged default subscrubed communities", ~m(guest_conn)a do
      {:ok, _} = db_insert_multi(:community, 25)

      variables = %{filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "subscribedCommunities")

      assert results |> is_valid_pagination?
      assert @default_subscribed_communities == results["pageSize"]
    end

    @query """
    query($userId: String, $filter: PagedFilter!) {
      subscribedCommunities(userId: $userId, filter: $filter) {
        entries {
          title
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "gest user can get paged default subscrubed communities with empty args",
         ~m(guest_conn)a do
      {:ok, _} = db_insert_multi(:community, 25)

      variables = %{userId: "", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "subscribedCommunities")

      assert results |> is_valid_pagination?
      assert @default_subscribed_communities == results["pageSize"]
    end
  end
end
