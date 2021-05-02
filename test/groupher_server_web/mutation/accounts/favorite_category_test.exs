defmodule GroupherServer.Test.Mutation.Accounts.FavoriteCategory do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  alias Accounts.FavoriteCategory

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, repo} = db_insert(:repo)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user post job repo)a}
  end

  describe "[Accounts FavoriteCategory CURD]" do
    @query """
    mutation($title: String!, $private: Boolean) {
      createFavoriteCategory(title: $title, private: $private) {
        id
        title
        lastUpdated
      }
    }
    """
    test "login user can create favorite category", ~m(user_conn)a do
      test_category = "test category"
      variables = %{title: test_category}
      created = user_conn |> mutation_result(@query, variables, "createFavoriteCategory")
      {:ok, found} = FavoriteCategory |> ORM.find(created |> Map.get("id"))

      assert created |> Map.get("id") == to_string(found.id)
      assert created["lastUpdated"] != nil
    end

    test "unauth user create category fails", ~m(guest_conn)a do
      test_category = "test category"
      variables = %{title: test_category}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $title: String, $desc: String, $private: Boolean) {
      updateFavoriteCategory(
        id: $id
        title: $title
        desc: $desc
        private: $private
      ) {
        id
        title
        desc
        private
        lastUpdated
      }
    }
    """
    test "login user can update own favorite category", ~m(user_conn user)a do
      test_category = "test category"

      {:ok, category} =
        Accounts.create_favorite_category(user, %{
          title: test_category,
          desc: "old desc",
          private: false
        })

      variables = %{id: category.id, title: "new title", desc: "new desc", private: true}
      updated = user_conn |> mutation_result(@query, variables, "updateFavoriteCategory")

      assert updated["desc"] == "new desc"
      assert updated["private"] == true
      assert updated["title"] == "new title"
      assert updated["lastUpdated"] != nil
    end

    @query """
    mutation($id: ID!) {
      deleteFavoriteCategory(id: $id) {
        done
      }
    }
    """
    test "login user can delete own favorite category", ~m(user_conn user)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      variables = %{id: category.id}
      deleted = user_conn |> mutation_result(@query, variables, "deleteFavoriteCategory")

      assert deleted["done"] == true
      assert {:error, _} = FavoriteCategory |> ORM.find(category.id)
    end

    test "after favorite deleted, the favroted action also be deleted ",
         ~m(user_conn user post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      {:ok, _favorite_category} = Accounts.set_favorites(user, :post, post.id, category.id)

      assert {:ok, _} =
               CMS.PostFavorite |> ORM.find_by(%{user_id: user.id, category_id: category.id})

      variables = %{id: category.id}
      user_conn |> mutation_result(@query, variables, "deleteFavoriteCategory")

      assert {:error, _} =
               CMS.PostFavorite |> ORM.find_by(%{user_id: user.id, category_id: category.id})
    end

    test "after favorite deleted, the related author's reputation should be downgrade",
         ~m(user_conn user post job)a do
      {:ok, author} = db_insert(:author)
      {:ok, post2} = db_insert(:post, %{author: author})
      {:ok, job2} = db_insert(:job, %{author: author})
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      test_category2 = "test category2"
      {:ok, category2} = Accounts.create_favorite_category(user, %{title: test_category2})

      {:ok, _} = Accounts.set_favorites(user, :post, post.id, category.id)
      {:ok, _} = Accounts.set_favorites(user, :post, post2.id, category.id)
      {:ok, _} = Accounts.set_favorites(user, :job, job.id, category.id)
      {:ok, _} = Accounts.set_favorites(user, :job, job2.id, category2.id)

      # author.id
      {:ok, achievement} = ORM.find_by(Accounts.Achievement, user_id: author.user.id)

      assert achievement.articles_collects_count == 2
      assert achievement.reputation == 4

      variables = %{id: category.id}
      user_conn |> mutation_result(@query, variables, "deleteFavoriteCategory")

      {:ok, achievement} = ORM.find_by(Accounts.Achievement, user_id: author.user.id)

      assert achievement.articles_collects_count == 1
      assert achievement.reputation == 2
    end
  end

  describe "[Accounts FavoriteCategory set/unset]" do
    @query """
    mutation($id: ID!, $thread: CmsThread, $categoryId: ID!) {
      setFavorites(id: $id, thread: $thread, categoryId: $categoryId) {
        id
        title
        totalCount
        lastUpdated
      }
    }
    """
    test "user can put a post to favorites category", ~m(user user_conn post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      variables = %{id: post.id, thread: "POST", categoryId: category.id}
      created = user_conn |> mutation_result(@query, variables, "setFavorites")
      {:ok, found} = CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      assert created["totalCount"] == 1
      assert created["lastUpdated"] != nil

      assert found.category_id == category.id
      assert found.user_id == user.id
      assert found.post_id == post.id
    end

    test "user can put a job to favorites category", ~m(user user_conn job)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      variables = %{id: job.id, thread: "JOB", categoryId: category.id}
      created = user_conn |> mutation_result(@query, variables, "setFavorites")
      {:ok, found} = CMS.JobFavorite |> ORM.find_by(%{job_id: job.id, user_id: user.id})

      assert created["totalCount"] == 1
      assert created["lastUpdated"] != nil

      assert found.category_id == category.id
      assert found.user_id == user.id
      assert found.job_id == job.id
    end

    test "user can put a repo to favorites category", ~m(user user_conn repo)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      variables = %{id: repo.id, thread: "REPO", categoryId: category.id}
      created = user_conn |> mutation_result(@query, variables, "setFavorites")
      {:ok, found} = CMS.RepoFavorite |> ORM.find_by(%{repo_id: repo.id, user_id: user.id})

      assert created["totalCount"] == 1
      assert created["lastUpdated"] != nil

      assert found.category_id == category.id
      assert found.user_id == user.id
      assert found.repo_id == repo.id
    end

    @query """
    mutation($id: ID!, $thread: CmsThread, $categoryId: ID!) {
      unsetFavorites(id: $id, thread: $thread, categoryId: $categoryId) {
        id
        title
        totalCount
        lastUpdated
      }
    }
    """
    test "user can unset a post to favorites category", ~m(user user_conn post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _favorite_category} = Accounts.set_favorites(user, :post, post.id, category.id)

      {:ok, category} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 1
      assert category.last_updated != nil

      variables = %{id: post.id, thread: "POST", categoryId: category.id}
      user_conn |> mutation_result(@query, variables, "unsetFavorites")

      {:ok, category} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 0
      assert {:error, _} = CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})
    end

    test "user can unset a job to favorites category", ~m(user user_conn job)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _favorite_category} = Accounts.set_favorites(user, :job, job.id, category.id)

      {:ok, category} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 1
      assert category.last_updated != nil

      variables = %{id: job.id, thread: "JOB", categoryId: category.id}
      user_conn |> mutation_result(@query, variables, "unsetFavorites")

      {:ok, category} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 0
      assert {:error, _} = CMS.JobFavorite |> ORM.find_by(%{job_id: job.id, user_id: user.id})
    end

    test "user can unset a repo to favorites category", ~m(user user_conn repo)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _favorite_category} = Accounts.set_favorites(user, :repo, repo.id, category.id)

      {:ok, category} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 1
      assert category.last_updated != nil

      variables = %{id: repo.id, thread: "REPO", categoryId: category.id}
      user_conn |> mutation_result(@query, variables, "unsetFavorites")

      {:ok, category} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 0
      assert {:error, _} = CMS.RepoFavorite |> ORM.find_by(%{repo_id: repo.id, user_id: user.id})
    end
  end
end
