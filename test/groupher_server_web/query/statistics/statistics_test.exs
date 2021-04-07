defmodule GroupherServer.Test.Query.Statistics do
  use GroupherServer.TestTools

  alias Helper.GeoPool
  alias GroupherServer.Accounts.User
  alias GroupherServer.Statistics

  setup do
    GeoPool.insert_geo_data()

    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)

    Statistics.make_contribute(%User{id: user.id})

    {:ok, ~m(guest_conn user)a}
  end

  describe "[statistics query user_contribute] " do
    @query """
    query($id: ID!) {
      userContributes(id: $id) {
        date
        count
      }
    }
    """
    test "query userContributes get valid count/date list", ~m(guest_conn user)a do
      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "userContributes")

      assert is_list(results)
      assert ["count", "date"] == results |> List.first() |> Map.keys()
    end
  end

  @query """
  query {
    citiesGeoInfo {
      entries {
        city
        value
        long
        lant
      }
      totalCount
    }
  }
  """
  describe "[statistics geo info]" do
    test "should get cities geo infos", ~m(guest_conn)a do
      result = guest_conn |> query_result(@query, %{}, "citiesGeoInfo")
      assert result["entries"] == []
      assert result["totalCount"] == 0

      {:ok, _} = Statistics.inc_count("成都")
      {:ok, _} = Statistics.inc_count("成都")
      {:ok, _} = Statistics.inc_count("广州")

      result = guest_conn |> query_result(@query, %{}, "citiesGeoInfo")
      assert result["totalCount"] == 2

      assert result["entries"] |> Enum.any?(&(&1["city"] == "成都"))
      assert result["entries"] |> Enum.any?(&(&1["city"] == "广州"))
    end
  end

  describe "[statistics count status]" do
    @query """
    query {
      countStatus {
        communitiesCount
        postsCount
        jobsCount
        reposCount
        categoriesCount
        tagsCount
        threadsCount
      }
    }
    """
    test "root manager should get count status" do
      passport_rules = %{"root" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> query_result(@query, %{}, "countStatus")
      assert result["postsCount"] == 0
    end
  end
end
