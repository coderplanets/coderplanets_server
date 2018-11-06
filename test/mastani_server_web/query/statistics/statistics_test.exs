defmodule MastaniServer.Test.Query.Statistics do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts.User
  alias MastaniServer.Statistics

  setup do
    insert_geo_data()

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
end
