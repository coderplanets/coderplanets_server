defmodule GroupherServer.Test.Query.Accounts.CollectedArticles do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts

  @total_count 20

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, posts} = db_insert_multi(:post, @total_count)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user posts)a}
  end

  @query """
  query($login: String!, $filter: CollectFoldersFilter!) {
    pagedCollectFolders(login: $login, filter: $filter) {
      entries {
        id
        title
        private
      }
      totalPages
      totalCount
      pageSize
      pageNumber
    }
  }
  """

  test "other user can get other user's paged collect folders", ~m(user_conn guest_conn)a do
    {:ok, user} = db_insert(:user)

    {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
    {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

    variables = %{login: user.login, filter: %{page: 1, size: 20}}
    results = user_conn |> query_result(@query, variables, "pagedCollectFolders")
    results2 = guest_conn |> query_result(@query, variables, "pagedCollectFolders")

    assert results["totalCount"] == 2
    assert results2["totalCount"] == 2

    assert results |> is_valid_pagination?()
    assert results2 |> is_valid_pagination?()
  end

  test "other user can get other user's paged collect folders filter by thread",
       ~m(guest_conn)a do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, job2} = db_insert(:job)

    {:ok, folder_post} = Accounts.create_collect_folder(%{title: "test folder2"}, user)
    {:ok, folder_job} = Accounts.create_collect_folder(%{title: "test folder"}, user)

    {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder_post.id, user)
    {:ok, _folder} = Accounts.add_to_collect(:job, job.id, folder_post.id, user)
    {:ok, _folder} = Accounts.add_to_collect(:job, job2.id, folder_job.id, user)

    variables = %{login: user.login, filter: %{thread: "JOB", page: 1, size: 20}}
    results = guest_conn |> query_result(@query, variables, "pagedCollectFolders")
    assert results["totalCount"] == 2

    variables = %{login: user.login, filter: %{thread: "POST", page: 1, size: 20}}
    results = guest_conn |> query_result(@query, variables, "pagedCollectFolders")
    assert results["totalCount"] == 1
  end

  test "owner can get it's paged collect folders with private folders",
       ~m(user user_conn guest_conn)a do
    {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder", private: true}, user)
    {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

    variables = %{login: user.login, filter: %{page: 1, size: 20}}
    results = user_conn |> query_result(@query, variables, "pagedCollectFolders")
    results2 = guest_conn |> query_result(@query, variables, "pagedCollectFolders")

    assert results["totalCount"] == 2
    assert results2["totalCount"] == 1
  end

  @query """
  query($folderId: ID!, $filter: CollectedArticlesFilter!) {
    pagedCollectedArticles(folderId: $folderId, filter: $filter) {
      entries {
        id
        title
      }
      totalPages
      totalCount
      pageSize
      pageNumber
    }
  }
  """

  test "can get paged articles inside a collect-folder", ~m(user_conn guest_conn user posts)a do
    {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)

    Enum.each(posts, fn post ->
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
    end)

    post1 = Enum.at(posts, 0)
    post2 = Enum.at(posts, 1)
    post3 = Enum.at(posts, 2)

    variables = %{folderId: folder.id, filter: %{page: 1, size: 20}}

    results = user_conn |> query_result(@query, variables, "pagedCollectedArticles")
    results2 = guest_conn |> query_result(@query, variables, "pagedCollectedArticles")

    assert results["totalCount"] == @total_count
    assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post1.id)))
    assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post2.id)))
    assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post3.id)))

    assert results == results2
  end

  test "can not get collect-folder articles when folder is private", ~m(guest_conn posts)a do
    {:ok, user2} = db_insert(:user)
    {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder", private: true}, user2)

    Enum.each(posts, fn post ->
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user2)
    end)

    variables = %{folderId: folder.id, filter: %{page: 1, size: 20}}

    assert guest_conn |> query_get_error?(@query, variables, ecode(:private_collect_folder))
  end

  test "owner can get collect-folder articles when folder is private",
       ~m(user_conn user posts)a do
    {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder", private: true}, user)

    Enum.each(posts, fn post ->
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
    end)

    variables = %{folderId: folder.id, filter: %{page: 1, size: 20}}

    results = user_conn |> query_result(@query, variables, "pagedCollectedArticles")

    assert results["totalCount"] == @total_count
  end
end
