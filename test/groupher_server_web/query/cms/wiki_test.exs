defmodule GroupherServer.Test.Query.Wiki do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, community} = db_insert(:community)

    wiki_attrs = mock_attrs(:wiki, %{community_id: community.id})
    {:ok, wiki} = CMS.sync_github_content(community, :wiki, wiki_attrs)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn community wiki)a}
  end

  @query """
  query($community: String!) {
    wiki(community: $community) {
      id
      readme
      contributors {
        avatar
        nickname
      }
    }
  }
  """
  test "basic graphql query on wiki", ~m(guest_conn community wiki)a do
    variables = %{community: community.raw}
    results = guest_conn |> query_result(@query, variables, "wiki")

    assert results["id"] == to_string(wiki.id)
    assert is_valid_kv?(results, "readme", :string)
    assert results["contributors"] |> length !== 0
  end

  test "non-exsit community should get empty wiki readme", ~m(guest_conn)a do
    variables = %{community: "non-exsit"}
    results = guest_conn |> query_result(@query, variables, "wiki")

    assert results["readme"] |> byte_size == 0
  end

  @query """
  query($community: String!) {
    wiki(community: $community) {
      views
    }
  }
  """
  test "views should +1 after query the wiki", ~m(guest_conn community)a do
    variables = %{community: community.raw}
    views_1 = guest_conn |> query_result(@query, variables, "wiki") |> Map.get("views")

    variables = %{community: community.raw}
    views_2 = guest_conn |> query_result(@query, variables, "wiki") |> Map.get("views")

    assert views_2 == views_1 + 1
  end
end
