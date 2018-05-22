defmodule MastaniServer.Test.Query.CMSTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.ConnSimulator
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  alias MastaniServer.{Accounts, CMS}

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)
    # user_conn = simu_conn(:user)

    {:ok, ~m(guest_conn community user)a}
  end

  describe "[cms query tags]" do
    @query """
    query tags($filter: PagedFilter!) {
      tags(filter: $filter) {
        entries {
          id
          title
          author {
            id
            nickname
            avatar
          }
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "authed user can get pagd tags", ~m(guest_conn community user)a do
      variables = %{filter: %{page: 1, size: 10}}

      valid_attrs = mock_attrs(:tag, %{user_id: user.id, community_id: community.id})
      {:ok, _} = CMS.create_tag(:post, valid_attrs, %Accounts.User{id: user.id})

      results = guest_conn |> query_result(@query, variables, "tags")

      assert results |> is_valid_pagination?
    end
  end

  describe "[cms query community]" do
    @query """
    query community($id: ID, $title: String) {
      community(id: $id, title: $title) {
        id
        title
        desc
      }
    }
    """
    test "guest user can get badic info of a community by id", ~m(guest_conn community)a do
      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")

      assert results["id"] == to_string(community.id)
      assert results["title"] == community.title
      assert results["desc"] == community.desc
    end

    test "guest user can get badic info of a community by title", ~m(guest_conn community)a do
      variables = %{title: community.title}
      results = guest_conn |> query_result(@query, variables, "community")

      assert results["id"] == to_string(community.id)
      assert results["title"] == community.title
      assert results["desc"] == community.desc
    end

    test "guest user can get community info without args fails", ~m(guest_conn)a do
      variables = %{}
      assert guest_conn |> query_get_error?(@query, variables)
    end
  end

  describe "[cms community editors]" do
    @query """
    query community($id: ID!) {
      community(id: $id) {
        id
        editorsCount
        editors {
          id
          nickname
        }
      }
    }
    """
    test "guest can get editors list and count of a community", ~m(guest_conn community)a do
      title = "chief editor"
      {:ok, users} = db_insert_multi(:user, inner_page_size())

      Enum.each(
        users,
        &CMS.add_editor_to_community(
          %Accounts.User{id: &1.id},
          %CMS.Community{id: community.id},
          title
        )
      )

      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")
      editors = results["editors"]
      editorsCount = results["editorsCount"]

      [user_1, user_2, user_3, user_x] = users |> firstn_and_last(3)

      assert results["id"] == to_string(community.id)
      assert editors |> Enum.any?(&(&1["id"] == to_string(user_1.id)))
      assert editors |> Enum.any?(&(&1["id"] == to_string(user_2.id)))
      assert editors |> Enum.any?(&(&1["id"] == to_string(user_3.id)))
      assert editors |> Enum.any?(&(&1["id"] == to_string(user_x.id)))
      assert editorsCount == inner_page_size()
    end

    @query """
    query communityEditors($id: ID!, $filter: PagedFilter!) {
      communityEditors(id: $id, filter: $filter) {
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
    test "guest user can get paged editors", ~m(guest_conn community)a do
      title = "chief editor"
      {:ok, users} = db_insert_multi(:user, 25)

      Enum.each(
        users,
        &CMS.add_editor_to_community(
          %Accounts.User{id: &1.id},
          %CMS.Community{id: community.id},
          title
        )
      )

      variables = %{id: community.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "communityEditors")

      assert results |> is_valid_pagination?
    end
  end

  describe "[cms community subscribe]" do
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
