defmodule GroupherServer.Test.Query.CMS.Basic do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts.Model.User
  alias GroupherServer.CMS
  alias CMS.Model.{Community, Category}
  alias Helper.ORM

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)

    {:ok, ~m(guest_conn community user)a}
  end

  describe "apply community" do
    @check_community_pending_query """
    query {
      hasPendingCommunityApply {
        exist
      }
    }
    """

    test "can check if user has penging apply", ~m(user)a do
      user_conn = simu_conn(:user, user)

      check_state =
        user_conn
        |> query_result(@check_community_pending_query, %{}, "hasPendingCommunityApply")

      assert not check_state["exist"]

      attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, _community} = CMS.apply_community(attrs)

      user_conn = simu_conn(:user, user)

      check_state =
        user_conn
        |> query_result(@check_community_pending_query, %{}, "hasPendingCommunityApply")

      assert check_state["exist"]
    end

    @check_community_exist_query """
    query($raw: String!) {
      isCommunityExist(raw: $raw) {
        exist
      }
    }
    """

    test "can check if a community is exist", ~m(user)a do
      rule_conn = simu_conn(:user, cms: %{"community.create" => true})

      check_state =
        rule_conn
        |> query_result(
          @check_community_exist_query,
          %{raw: "elixir"},
          "isCommunityExist"
        )

      assert not check_state["exist"]

      community_attrs = mock_attrs(:community, %{raw: "elixir", user_id: user.id})
      {:ok, _community} = CMS.create_community(community_attrs)

      check_state =
        rule_conn
        |> query_result(@check_community_exist_query, %{raw: "elixir"}, "isCommunityExist")

      assert check_state["exist"]
    end
  end

  describe "[cms communities]" do
    @query """
    query($raw: String) {
      community(raw: $raw) {
        id
        title
        threadsCount
        articleTagsCount
        views
        threads {
          id
          raw
          index
        }
      }
    }
    """

    test "views should work", ~m(guest_conn)a do
      {:ok, community} = db_insert(:community)

      variables = %{raw: community.raw}
      guest_conn |> query_result(@query, variables, "community")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.views == 1
      guest_conn |> query_result(@query, variables, "community")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.views == 2
    end

    test "can get from alias community name", ~m(guest_conn)a do
      {:ok, _community} = db_insert(:community, %{raw: "kubernetes", aka: "k8s"})

      variables = %{raw: "k8s"}
      aka_results = guest_conn |> query_result(@query, variables, "community")

      variables = %{raw: "kubernetes"}
      results = guest_conn |> query_result(@query, variables, "community")

      assert results["id"] == aka_results["id"]
    end

    test "can get threads count ", ~m(community guest_conn)a do
      {:ok, threads} = db_insert_multi(:thread, 5)

      Enum.map(threads, fn thread ->
        CMS.set_thread(community, thread)
      end)

      variables = %{raw: community.raw}
      results = guest_conn |> query_result(@query, variables, "community")

      assert results["threadsCount"] == 5
    end

    test "can get tags count ", ~m(community guest_conn user)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, _article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, _article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)

      variables = %{raw: community.raw}
      results = guest_conn |> query_result(@query, variables, "community")

      assert results["articleTagsCount"] == 2
    end

    test "guest use get community threads with default asc sort index",
         ~m(guest_conn community)a do
      {:ok, threads} = db_insert_multi(:thread, 5)

      Enum.map(threads, fn thread ->
        CMS.set_thread(community, thread)
      end)

      variables = %{raw: community.raw}
      results = guest_conn |> query_result(@query, variables, "community")

      first_idx = results["threads"] |> List.first() |> Map.get("index")
      last_idx = results["threads"] |> List.last() |> Map.get("index")

      assert first_idx < last_idx
    end

    @query """
    query($filter: CommunitiesFilter!) {
      pagedCommunities(filter: $filter) {
        entries {
          id
          title
          index
          viewerHasSubscribed
          categories {
            id
            title
            raw
          }
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "user can get viewer has subscribed state", ~m(guest_conn user)a do
      {:ok, communities} = db_insert_multi(:community, 5)
      {:ok, record} = CMS.subscribe_community(communities |> List.first(), user)

      variables = %{filter: %{page: 1, size: 20}}
      user_conn = simu_conn(:user, user)
      results = user_conn |> query_result(@query, variables, "pagedCommunities")

      assert results["entries"] |> List.last() |> Map.get("viewerHasSubscribed")
    end

    test "guest user can get paged communities", ~m(guest_conn)a do
      {:ok, _communities} = db_insert_multi(:community, 5)

      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedCommunities")

      assert results |> is_valid_pagination?
      # 1 is for setup community
      assert results["totalCount"] == 5 + 1
    end

    test "community has default index = 100000", ~m(guest_conn)a do
      {:ok, _communities} = db_insert_multi(:community, 5)
      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedCommunities")

      results["entries"] |> Enum.all?(fn x -> x["index"] == 100_000 end)
    end

    test "guest user can get paged communities based on category", ~m(guest_conn)a do
      {:ok, category1} = db_insert(:category)
      {:ok, category2} = db_insert(:category)

      {:ok, communities} = db_insert_multi(:community, 10)

      community1 = communities |> Enum.at(0)
      community2 = communities |> Enum.at(1)
      communityn = communities |> List.last()
      # [community1, community2, _] = communities

      CMS.set_category(%Community{id: community1.id}, %Category{id: category1.id})
      CMS.set_category(%Community{id: community2.id}, %Category{id: category2.id})
      CMS.set_category(%Community{id: communityn.id}, %Category{id: category2.id})

      variables = %{filter: %{page: 1, size: 20, category: category1.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedCommunities")

      assert results["entries"]
             |> List.first()
             |> Map.get("categories")
             |> Enum.any?(&(&1["id"] == to_string(category1.id)))

      assert results["totalCount"] == 1

      variables = %{filter: %{page: 1, size: 20, category: category2.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedCommunities")

      assert results["totalCount"] == 2

      assert results["entries"]
             |> List.first()
             |> Map.get("categories")
             |> Enum.any?(&(&1["id"] == to_string(category2.id)))

      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedCommunities")

      assert results["totalCount"] == 10 + 1
    end
  end

  describe "[cms threads]" do
    @query """
    query($filter: ThreadsFilter!) {
      pagedThreads(filter: $filter) {
        entries {
          id
          title
          raw
          index
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "can get whole threads", ~m(guest_conn)a do
      {:ok, _threads} = db_insert_multi(:thread, 5)

      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedThreads")
      assert results |> is_valid_pagination?
      assert results["totalCount"] == 5
    end

    test "can get sorted thread based on index", ~m(guest_conn)a do
      {:ok, _threads} = db_insert_multi(:thread, 10)

      variables = %{filter: %{page: 1, size: 20, sort: "DESC_INDEX"}}
      results = guest_conn |> query_result(@query, variables, "pagedThreads")
      first_idx = results["entries"] |> List.first() |> Map.get("index")
      last_idx = results["entries"] |> List.last() |> Map.get("index")

      assert first_idx > last_idx

      variables = %{filter: %{page: 1, size: 20, sort: "ASC_INDEX"}}
      results = guest_conn |> query_result(@query, variables, "pagedThreads")
      first_idx = results["entries"] |> List.first() |> Map.get("index")
      last_idx = results["entries"] |> List.last() |> Map.get("index")

      assert first_idx < last_idx
    end
  end

  describe "[cms query categories]" do
    @query """
    query($filter: PagedFilter!) {
      pagedCategories(filter: $filter) {
        entries {
          id
          title
          author {
            id
            nickname
          }
          communities {
            id
            title
          }
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "guest user can get paged categories", ~m(guest_conn user)a do
      variables = %{filter: %{page: 1, size: 10}}
      valid_attrs = mock_attrs(:category)
      ~m(title raw)a = valid_attrs

      {:ok, _} = CMS.create_category(~m(title raw)a, %User{id: user.id})

      results = guest_conn |> query_result(@query, variables, "pagedCategories")
      author = results["entries"] |> List.first() |> Map.get("author")

      assert results |> is_valid_pagination?
      assert author["id"] == to_string(user.id)
    end

    test "paged categories containes communities info", ~m(guest_conn user community)a do
      variables = %{filter: %{page: 1, size: 10}}
      valid_attrs = mock_attrs(:category)
      ~m(title raw)a = valid_attrs

      {:ok, category} = CMS.create_category(~m(title raw)a, %User{id: user.id})

      {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: category.id})

      results = guest_conn |> query_result(@query, variables, "pagedCategories")
      contain_communities = results["entries"] |> List.first() |> Map.get("communities")

      assert contain_communities |> List.first() |> Map.get("id") == to_string(community.id)
    end
  end

  describe "[cms query community]" do
    @query """
    query($raw: String!) {
      community(raw: $raw, title: $title) {
        id
        title
        desc
      }
    }
    """

    test "guest user can get community info without args fails", ~m(guest_conn)a do
      variables = %{}
      assert guest_conn |> query_get_error?(@query, variables)
    end
  end

  describe "[cms community editors]" do
    @query """
    query($raw: String!) {
      community(raw: $raw) {
        id
        editorsCount
      }
    }
    """

    test "guest can get editors count of a community", ~m(guest_conn community)a do
      title = "chief editor"
      {:ok, users} = db_insert_multi(:user, assert_v(:inner_page_size))

      Enum.each(users, &CMS.set_editor(community, title, %User{id: &1.id}))

      variables = %{raw: community.raw}
      results = guest_conn |> query_result(@query, variables, "community")
      editors_count = results["editorsCount"]

      assert results["id"] == to_string(community.id)
      assert editors_count == assert_v(:inner_page_size)
    end

    @query """
    query($id: ID!, $filter: PagedFilter!) {
      pagedCommunityEditors(id: $id, filter: $filter) {
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

      Enum.each(users, &CMS.set_editor(community, title, %User{id: &1.id}))

      variables = %{id: community.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedCommunityEditors")

      assert results |> is_valid_pagination?
    end
  end

  describe "[cms community subscribe]" do
    @query """
    query($raw: String!) {
      community(raw: $raw) {
        id
        subscribersCount
      }
    }
    """

    test "guest can get subscribers count of a community", ~m(guest_conn community)a do
      {:ok, users} = db_insert_multi(:user, assert_v(:inner_page_size))

      Enum.each(users, &CMS.subscribe_community(community, %User{id: &1.id}))

      variables = %{raw: community.raw}
      results = guest_conn |> query_result(@query, variables, "community")
      subscribers_count = results["subscribersCount"]

      assert subscribers_count == assert_v(:inner_page_size)
    end

    @query """
    query($id: ID, $community: String, $filter: PagedFilter!) {
      pagedCommunitySubscribers(id: $id, community: $community, filter: $filter) {
        entries {
          id
          nickname
          avatar
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "guest user can get paged subscribers by community id", ~m(guest_conn community)a do
      {:ok, users} = db_insert_multi(:user, 25)

      Enum.each(
        users,
        &CMS.subscribe_community(community, %User{id: &1.id})
      )

      variables = %{id: community.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedCommunitySubscribers")

      assert results |> is_valid_pagination?
    end

    test "guest user can get paged subscribers by community raw", ~m(guest_conn community)a do
      {:ok, users} = db_insert_multi(:user, 25)

      Enum.each(
        users,
        &CMS.subscribe_community(community, %User{id: &1.id})
      )

      variables = %{community: community.raw, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedCommunitySubscribers")

      assert results |> is_valid_pagination?
    end
  end
end
