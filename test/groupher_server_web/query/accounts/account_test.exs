defmodule GroupherServer.Test.Query.Account.Basic do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias CMS.Model.CommunitySubscriber

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
        meta {
          publishedPostsCount
          publishedJobsCount
          publishedBlogsCount
          publishedWorksCount
          publishedRadarsCount
          publishedMeetupsCount
        }
        views
        cmsPassport
        cmsPassportString
        subscribedCommunitiesCount
        followersCount
        followingsCount
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
      }
    }
    """
    test "guest user can get specific user's info by user's id", ~m(guest_conn user)a do
      variables = %{login: user.login}
      results = guest_conn |> query_result(@query, variables, "user")

      assert not is_nil(results["meta"])

      assert results["id"] == to_string(user.id)
      assert results["nickname"] == user.nickname
      assert results["educationBackgrounds"] == []
      assert results["workBackgrounds"] == []
      assert results["social"]["github"] == nil
      assert results["social"]["douban"] == nil
      assert results["cmsPassport"] == nil

      assert results["subscribedCommunitiesCount"] == 0
      assert results["followersCount"] == 0
      assert results["followingsCount"] == 0
    end

    test "user should have default contributes", ~m(guest_conn user_conn user)a do
      variables = %{login: user.login}
      results = guest_conn |> query_result(@query, variables, "user")

      contributes = results["contributes"]

      assert contributes["records"] == []
      assert contributes["totalCount"] == 0

      results = user_conn |> query_result(@query, variables, "user")

      contributes = results["contributes"]

      assert contributes["records"] == []
      assert contributes["totalCount"] == 0
    end

    test "login user can get it's own profile", ~m(user_conn user)a do
      results = user_conn |> query_result(@query, %{login: user.login}, "user")
      assert results["id"] == to_string(user.id)
    end

    test "user's views +1 after visit", ~m(guest_conn user)a do
      {:ok, target_user} = ORM.find(User, user.id)
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

      results = user_conn |> query_result(@query, %{login: user.login}, "user")

      assert Map.equal?(results["cmsPassport"], @valid_rules)
      assert Map.equal?(Jason.decode!(results["cmsPassportString"]), @valid_rules)
    end

    test "login user can get empty if cms_passport not exsit", ~m(user)a do
      user_conn = simu_conn(:user, user)

      results = user_conn |> query_result(@query, %{login: user.login}, "user")

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
          viewerHasFollowed
          viewerBeenFollowed
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

    test "login user can get paged users with follow state info", ~m(user_conn user)a do
      variables = %{filter: %{page: 1, size: 10}}

      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)

      {:ok, _} = Accounts.follow(user, user2)
      {:ok, _} = Accounts.follow(user3, user)

      results = user_conn |> query_result(@query, variables, "pagedUsers")
      assert results |> is_valid_pagination?()

      entries = results["entries"]

      user3 = Enum.find(entries, &(&1["id"] == to_string(user3.id)))
      assert user3["viewerBeenFollowed"]

      user2 = Enum.find(entries, &(&1["id"] == to_string(user2.id)))
      assert user2["viewerHasFollowed"]
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
    query($login: String, $filter: PagedFilter!) {
      subscribedCommunities(login: $login, filter: $filter) {
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

      variables = %{filter: %{page: 1, size: 10}}
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
        ORM.find_by(CommunitySubscriber, %{community_id: community.id, user_id: user.id})

      assert record.user_id == user.id
      assert record.community_id == community.id
    end
  end
end
