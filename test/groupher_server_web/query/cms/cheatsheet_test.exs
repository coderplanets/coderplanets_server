defmodule GroupherServer.Test.Query.Cheatsheet do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, community} = db_insert(:community)

    cheatsheet_attrs = mock_attrs(:cheatsheet, %{community_id: community.id})
    {:ok, cheatsheet} = CMS.sync_github_content(community, :cheatsheet, cheatsheet_attrs)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn community cheatsheet)a}
  end

  @query """
  query($community: String!) {
    cheatsheet(community: $community) {
      id
      readme
      contributors {
        avatar
        nickname
      }
    }
  }
  """
  test "basic graphql query on cheatsheet", ~m(guest_conn community cheatsheet)a do
    variables = %{community: community.raw}
    results = guest_conn |> query_result(@query, variables, "cheatsheet")

    assert results["id"] == to_string(cheatsheet.id)
    assert is_valid_kv?(results, "readme", :string)
    assert results["contributors"] |> length !== 0
  end

  test "non-exsit community should get empty cheatsheet readme", ~m(guest_conn)a do
    variables = %{community: "non-exsit"}
    results = guest_conn |> query_result(@query, variables, "cheatsheet")

    assert results["readme"] |> byte_size == 0
  end

  @query """
  query($community: String!) {
    cheatsheet(community: $community) {
      views
    }
  }
  """
  test "views should +1 after query the cheatsheet", ~m(guest_conn community)a do
    variables = %{community: community.raw}
    views_1 = guest_conn |> query_result(@query, variables, "cheatsheet") |> Map.get("views")

    variables = %{community: community.raw}
    views_2 = guest_conn |> query_result(@query, variables, "cheatsheet") |> Map.get("views")

    assert views_2 == views_1 + 1
  end
end
