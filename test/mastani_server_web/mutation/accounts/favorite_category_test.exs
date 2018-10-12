defmodule MastaniServer.Test.Mutation.Accounts.FavoriteCategory do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.{Accounts, CMS}

  alias Accounts.FavoriteCategory

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user post)a}
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

      variables = %{id: post.id, categoryId: category.id}
      created = user_conn |> mutation_result(@query, variables, "setFavorites")
      {:ok, found} = CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      assert created["totalCount"] == 1
      assert created["lastUpdated"] != nil

      assert found.category_id == category.id
      assert found.user_id == user.id
      assert found.post_id == post.id
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
    test "user can unset favorites category", ~m(user user_conn post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _favorite_category} = Accounts.set_favorites(user, :post, post.id, category.id)

      {:ok, category} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 1
      assert category.last_updated != nil

      variables = %{id: post.id, categoryId: category.id}
      user_conn |> mutation_result(@query, variables, "unsetFavorites")

      {:ok, category} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 0
      assert {:error, _} = CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})
    end
  end
end
