defmodule MastaniServer.Test.Query.CMSTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  alias MastaniServer.{Accounts, CMS}

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, community} = db_insert(:community)
    # user_conn = simu_conn(:user)

    {:ok, ~m(guest_conn community)a}
  end

  describe "[cms community subscribe]" do
    @query """
    query community($id: ID!) {
      community(id: $id) {
        id
        title
        desc
      }
    }
    """
    test "guest user can get badic info a community", ~m(guest_conn community)a do
      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")

      assert results["id"] == to_string(community.id)
      assert results["title"] == community.title
      assert results["desc"] == community.desc
    end

    @query """
    query community($id: ID!) {
      community(id: $id) {
        id
        subscribersCount
        subscribers {
          id
          nickname
        }
      }
    }
    """
    test "guest can get subscribers list and count of a community", ~m(guest_conn community)a do
      {:ok, users} = db_insert_multi(:user, inner_page_size())

      Enum.each(
        users,
        &CMS.subscribe_community(%Accounts.User{id: &1.id}, %CMS.Community{id: community.id})
      )

      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")
      subscribers = results["subscribers"]
      subscribersCount = results["subscribersCount"]

      [user_1, user_2, user_3, user_x] = users |> firstn_and_last(3)

      assert results["id"] == to_string(community.id)
      assert subscribers |> Enum.any?(&(&1["id"] == to_string(user_1.id)))
      assert subscribers |> Enum.any?(&(&1["id"] == to_string(user_2.id)))
      assert subscribers |> Enum.any?(&(&1["id"] == to_string(user_3.id)))
      assert subscribers |> Enum.any?(&(&1["id"] == to_string(user_x.id)))
      assert subscribersCount == inner_page_size()
    end

    test "guest user can get subscribers count of 20 at most", ~m(guest_conn community)a do
      {:ok, users} = db_insert_multi(:user, inner_page_size() + 1)

      Enum.each(
        users,
        &CMS.subscribe_community(%Accounts.User{id: &1.id}, %CMS.Community{id: community.id})
      )

      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")
      subscribers = results["subscribers"]

      assert length(subscribers) == inner_page_size()
    end

    @query """
    query communitySubscribers($id: ID!, $filter: PagedFilter!) {
      communitySubscribers(id: $id, filter: $filter) {
        entries {
          nickname
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "guest user can get paged subscribers", ~m(guest_conn community)a do
      {:ok, users} = db_insert_multi(:user, 25)

      Enum.each(
        users,
        &CMS.subscribe_community(%Accounts.User{id: &1.id}, %CMS.Community{id: community.id})
      )

      variables = %{id: community.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "communitySubscribers")

      assert results |> is_valid_pagination?
    end
  end
end
