defmodule GroupherServer.Test.Accounts.FavoriteCategory do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  alias Accounts.FavoriteCategory

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, post2} = db_insert(:post)

    {:ok, ~m(user post post2)a}
  end

  describe "[favorite category curd]" do
    test "user can create favorite category", ~m(user)a do
      test_category = "test category"

      {:ok, category} =
        Accounts.create_favorite_category(user, %{title: test_category, private: true})

      assert category.title == test_category
      assert category.user_id == user.id
      assert category.private == true
    end

    test "user create dup favorite category fails", ~m(user)a do
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: "test category"})
      {:error, reason} = Accounts.create_favorite_category(user, %{title: "test category"})

      assert reason |> Keyword.get(:code) == ecode(:already_exsit)
    end

    test "user can get public categories list", ~m(user)a do
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: "test category"})
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: "test category2"})

      {:ok, result} =
        Accounts.list_favorite_categories(user, %{private: false}, %{page: 1, size: 20})

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 2
    end

    test "user can update a favorite category", ~m(user)a do
      {:ok, category} = Accounts.create_favorite_category(user, %{title: "test category"})

      {:ok, updated} =
        Accounts.update_favorite_category(user, %{id: category.id, desc: "new desc"})

      assert updated.desc == "new desc"

      {:ok, updated} = Accounts.update_favorite_category(user, %{id: category.id, private: true})
      assert updated.private == true
    end

    test "user can delete a favorite category", ~m(user post post2)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, category.id)
      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post2.id, category.id)

      assert {:ok, _} = Accounts.delete_favorite_category(user, category.id)

      assert {:error, _} =
               CMS.PostFavorite
               |> ORM.find_by(%{category_id: category.id, user_id: user.id})

      assert {:error, _} = FavoriteCategory |> ORM.find(category.id)
    end
  end

  describe "[favorite category set/unset]" do
    test "user can set category to a favorited post", ~m(user post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post.id, category.id)

      {:ok, post_favorite} =
        CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      assert post_favorite.category_id == category.id
    end

    test "user can change category to a categoried favorited post", ~m(user post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
      {:ok, _favorite_category} = Accounts.set_favorites(user, :post, post.id, category.id)

      {:ok, post_favorite} =
        CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      assert post_favorite.category_id == category.id

      test_category2 = "test category2"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category2})
      {:ok, _favorite_category} = Accounts.set_favorites(user, :post, post.id, category.id)

      {:ok, post_favorite} =
        CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      assert post_favorite.category_id == category.id
    end

    test "user set a un-created user's category fails", ~m(user post)a do
      {:ok, user2} = db_insert(:user)
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user2, %{title: test_category})

      assert {:error, _} = Accounts.set_favorites(user, :post, post.id, category.id)
    end

    test "user set to a already categoried post fails", ~m(user post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _} = Accounts.set_favorites(user, :post, post.id, category.id)

      {:error, reason} = Accounts.set_favorites(user, :post, post.id, category.id)
      assert reason |> Keyword.get(:code) == ecode(:already_did)
    end

    test "user can unset category to a favorited post", ~m(user post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, category.id)
      assert {:ok, _} = CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      {:ok, _category} = Accounts.unset_favorites(user, :post, post.id, category.id)

      assert {:error, _} = CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})
    end

    test "after unset category the old category count should -1", ~m(user post)a do
      test_category = "test category"
      test_category2 = "test category2"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, category2} = Accounts.create_favorite_category(user, %{title: test_category2})

      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, category.id)
      {:ok, favorete_cat} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert favorete_cat.total_count == 1

      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, category2.id)
      {:ok, favorete_cat} = Accounts.FavoriteCategory |> ORM.find(category2.id)
      assert favorete_cat.total_count == 1

      {:ok, favorete_cat} = Accounts.FavoriteCategory |> ORM.find(category.id)
      assert favorete_cat.total_count == 0
    end
  end

  describe "[favorite category total_count]" do
    test "total_count + 1 after set category to a favorited post", ~m(user post post2)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      assert category.total_count == 0

      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, category.id)

      {:ok, category} = FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 1

      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post2.id, category.id)
      {:ok, category} = FavoriteCategory |> ORM.find(category.id)

      assert category.total_count == 2
    end

    test "total_count - 1 after unset category to a favorited post", ~m(user post)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, category.id)

      {:ok, category} = Accounts.unset_favorites(user, :post, post.id, category.id)

      assert category.total_count == 0
    end
  end
end
