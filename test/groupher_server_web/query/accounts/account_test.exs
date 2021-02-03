defmodule GroupherServer.Test.Query.Account.Basic do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  @default_subscribed_communities get_config(:general, :default_subscribed_communities)

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)
    {:ok, ~m(guest_conn user_conn user)a}
  end

  describe "[account basic]" do
    @query """
    query($login: String) {
      user(login: $login) {
        id
        nickname
        bio
        views
        cmsPassport
        cmsPassportString
        contributes {
          records {
            count
            date
          }
          startDate
          endDate
          totalCount
        }
        social {
          github
          douban
        }
        educationBackgrounds {
          school
          major
        }
        workBackgrounds {
          company
          title
        }
        subscribedCommunities {
          entries {
            id
          }
          pageSize
          totalCount
        }
      }
    }
    """
    test "guest user can get specific user's info by user's id", ~m(guest_conn user)a do
      variables = %{login: user.login}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results["id"] == to_string(user.id)
      assert results["nickname"] == user.nickname
      assert results["educationBackgrounds"] == []
      assert results["workBackgrounds"] == []
      assert results["social"]["github"] == nil
      assert results["social"]["douban"] == nil
      assert results["cmsPassport"] == nil
    end

    test "login user can get it's own profile", ~m(user_conn user)a do
      results = user_conn |> query_result(@query, %{}, "user")
      assert results["id"] == to_string(user.id)
    end

    test "user's views +1 after visit", ~m(guest_conn user)a do
      {:ok, target_user} = ORM.find(Accounts.User, user.id)
      assert target_user.views == 0

      variables = %{login: user.login}
      results = guest_conn |> query_result(@query, variables, "user")
      assert results["views"] == 1
    end

    test "login newbie user can get own empty cms_passport", ~m(user)a do
      user_conn = simu_conn(:user, user)
      variables = %{login: user.login}
      results = user_conn |> query_result(@query, variables, "user")

      assert results["cmsPassport"] == %{}
      assert results["cmsPassportString"] == "{}"
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

      results = user_conn |> query_result(@query, %{}, "user")

      assert Map.equal?(results["cmsPassport"], @valid_rules)
      assert Map.equal?(Jason.decode!(results["cmsPassportString"]), @valid_rules)
    end

    test "login user can get empty if cms_passport not exsit", ~m(user)a do
      user_conn = simu_conn(:user, user)

      results = user_conn |> query_result(@query, %{}, "user")

      assert %{} == results["cmsPassport"]
      assert "{}" == results["cmsPassportString"]
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
    alias CMS.Community

    @query """
    query($login: String!) {
      user(login: $login) {
        id
        nickname
        subscribedCommunitiesCount
        subscribedCommunities {
          entries {
            id
            title
            raw
            index
          }
          pageSize
          totalCount
        }
      }
    }
    """
    test "guest user can get subscrubed communities list and count", ~m(guest_conn user)a do
      variables = %{login: user.login}
      {:ok, communities} = db_insert_multi(:community, assert_v(:page_size))

      Enum.each(
        communities,
        &CMS.subscribe_community(%Community{id: &1.id}, user)
      )

      results = guest_conn |> query_result(@query, variables, "user")
      subscribed_communities = results["subscribedCommunities"]["entries"]

      subscribed_communities_count = results["subscribedCommunitiesCount"]
      [community_1, community_2, community_3, community_x] = communities |> firstn_and_last(3)

      assert subscribed_communities |> Enum.any?(&(&1["id"] == to_string(community_1.id)))
      assert subscribed_communities |> Enum.any?(&(&1["id"] == to_string(community_2.id)))
      assert subscribed_communities |> Enum.any?(&(&1["id"] == to_string(community_3.id)))
      assert subscribed_communities |> Enum.any?(&(&1["id"] == to_string(community_x.id)))
      assert subscribed_communities_count == assert_v(:page_size)
    end

    test "guest user can get subscrubed community list by index", ~m(guest_conn user)a do
      variables = %{login: user.login}
      {:ok, communities} = db_insert_multi(:community, assert_v(:page_size))

      Enum.each(
        communities,
        &CMS.subscribe_community(%Community{id: &1.id}, user)
      )

      [community_1, community_2, community_3, _community_x] = communities |> firstn_and_last(3)

      {:ok, _} =
        Accounts.set_customization(user, %{
          sidebar_communities_index: %{
            community_1.raw => 3,
            community_2.raw => 2,
            community_3.raw => 1
          }
        })

      results = guest_conn |> query_result(@query, variables, "user")
      subscribed_communities = results["subscribedCommunities"]["entries"]

      found_community_1 =
        Enum.find(subscribed_communities, fn c -> c["raw"] == community_1.raw end)

      found_community_2 =
        Enum.find(subscribed_communities, fn c -> c["raw"] == community_2.raw end)

      found_community_3 =
        Enum.find(subscribed_communities, fn c -> c["raw"] == community_3.raw end)

      assert found_community_1["index"] == 3
      assert found_community_2["index"] == 2
      assert found_community_3["index"] == 1
    end

    test "guest user can get subscrubed communities count of 20 at most", ~m(guest_conn user)a do
      variables = %{login: user.login}
      {:ok, communities} = db_insert_multi(:community, assert_v(:page_size) + 1)

      Enum.each(
        communities,
        &CMS.subscribe_community(%Community{id: &1.id}, user)
      )

      results = guest_conn |> query_result(@query, variables, "user")
      subscribed_communities = results["subscribedCommunities"]

      assert subscribed_communities["totalCount"] == assert_v(:page_size) + 1
      assert subscribed_communities["pageSize"] == assert_v(:page_size)
    end

    @query """
    query($filter: PagedFilter!) {
      subscribedCommunities(filter: $filter) {
        entries {
          title
          raw
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "guest user can get paged default subscrubed communities", ~m(guest_conn)a do
      {:ok, _} = db_insert_multi(:community, 25)
      {:ok, _} = db_insert(:community, %{raw: "home"})

      variables = %{filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "subscribedCommunities")

      assert results |> is_valid_pagination?
      assert @default_subscribed_communities == results["pageSize"]
    end

    test "guest user can get paged default subscrubed communities with home included",
         ~m(guest_conn)a do
      {:ok, _} = db_insert_multi(:community, 25)
      {:ok, _} = db_insert(:community, %{raw: "home"})

      variables = %{filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "subscribedCommunities")

      assert results["entries"] |> Enum.any?(&(&1["raw"] == "home"))
    end

    @query """
    query($userId: ID, $filter: PagedFilter!) {
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
    test "guest user can get paged default subscrubed communities with empty args",
         ~m(guest_conn)a do
      {:ok, _} = db_insert_multi(:community, 25)

      variables = %{userId: "", filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "subscribedCommunities")

      assert results |> is_valid_pagination?
      assert @default_subscribed_communities == results["pageSize"]
    end
  end

  describe "[account session state]" do
    @query """
    query {
      sessionState {
        isValid
        user {
          id
        }
      }
    }
    """
    test "guest user should get false sessionState", ~m(guest_conn)a do
      results = guest_conn |> query_result(@query, %{}, "sessionState")
      assert results["isValid"] == false
      assert results["user"] == nil
    end

    test "login user should get true sessionState", ~m(user)a do
      user_conn = simu_conn(:user, user)
      results = user_conn |> query_result(@query, %{}, "sessionState")

      assert results["isValid"] == true
      assert results["user"] |> Map.get("id") == to_string(user.id)
    end

    test "user with invalid token get false sessionState" do
      user_conn = simu_conn(:invalid_token)
      results = user_conn |> query_result(@query, %{}, "sessionState")

      assert results["isValid"] == false
      assert results["user"] == nil
    end

    test "user should subscribe home community if not subscribed before", ~m(user)a do
      {:ok, community} = db_insert(:community, %{raw: "home"})

      user_conn = simu_conn(:user, user)
      _results = user_conn |> query_result(@query, %{}, "sessionState")

      {:ok, record} =
        ORM.find_by(CMS.CommunitySubscriber, %{community_id: community.id, user_id: user.id})

      assert record.user_id == user.id
      assert record.community_id == community.id
    end
  end
end
