defmodule MastaniServer.Test.Query.CMS.GEO do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)

    {:ok, ~m(guest_conn community user)a}
  end

  @query """
  query($id: ID) {
    communityGeoInfo(id: $id) {
      city
      long
      lant
      value
    }
  }
  """
  @tag :wip
  test "empty community should get empty geo info", ~m(guest_conn community)a do
    variables = %{id: community.id}
    results = guest_conn |> query_result(@query, variables, "communityGeoInfo")

    assert results == []
  end

  @tag :wip
  test "community should get geo info after subscribe", ~m(guest_conn community user)a do
    {:ok, _record} = CMS.subscribe_community(community, user)

    variables = %{id: community.id}
    results = guest_conn |> query_result(@query, variables, "communityGeoInfo")

    assert results |> List.first() |> Map.get("value") == 1
    assert results |> List.first() |> Map.get("city") == "成都"
  end
end
