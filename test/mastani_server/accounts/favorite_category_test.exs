defmodule MastaniServer.Test.Accounts.FavoriteCategoryTest do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.{Accounts, CMS}

  alias Accounts.FavoriteCategory

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, post2} = db_insert(:post)

    {:ok, ~m(user post post2)a}
  end

  describe "[favorite category curd]" do
    @tag :wip
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
      {:error, error} = Accounts.create_favorite_category(user, %{title: "test category"})

      assert error |> Keyword.get(:code) == ecode(:already_exsit)
    end

    @tag :wip
    test "user can get public categories list", ~m(user)a do
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: "test category"})
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: "test category2"})

      {:ok, result} =
        Accounts.list_favorite_categories(user, %{private: false}, %{page: 1, size: 20})

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 2
    end

    @tag :wip
    test "user can update a favorite category", ~m(user)a do
      {:ok, category} = Accounts.create_favorite_category(user, %{title: "test category"})

      {:ok, updated} =
        Accounts.update_favorite_category(user, %{id: category.id, desc: "new desc"})

      assert updated.desc == "new desc"

      {:ok, updated} = Accounts.update_favorite_category(user, %{id: category.id, private: true})
      assert updated.private == true
    end

    @tag :wip
    test "user can delete a favorite category", ~m(user post post2)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})

      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, category.title)
      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post2.id, category.title)

      assert {:ok, _} = Accounts.delete_favorite_category(user, category.id)

      assert {:error, _} =
               CMS.PostFavorite
               |> ORM.find_by(%{category_title: category.title, user_id: user.id})

      assert {:error, _} = FavoriteCategory |> ORM.find(category.id)
    end
  end

  describe "[favorite category set/unset]" do
    @tag :wip
    test "user can set category to a favorited post", ~m(user post)a do
      test_category = "test category"
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: test_category})

      {:ok, _favorites_category} = Accounts.set_favorites(user, :post, post.id, test_category)

      {:ok, post_favorite} =
        CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      assert post_favorite.category_title == test_category
    end

    @tag :wip
    test "user can change category to a categoried favorited post", ~m(user post)a do
      test_category = "test category"
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: test_category})

      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
      {:ok, _favorite_category} = Accounts.set_favorites(user, :post, post.id, test_category)

      {:ok, post_favorite} =
        CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      assert post_favorite.category_title == test_category

      test_category2 = "test category2"
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: test_category2})
      {:ok, _favorite_category} = Accounts.set_favorites(user, :post, post.id, test_category2)

      {:ok, post_favorite} =
        CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      assert post_favorite.category_title == test_category2
    end

    @tag :wip
    test "user set a un-created user's category fails", ~m(user post)a do
      test_category = "test category"

      assert {:error, _} = Accounts.set_favorites(user, :post, post.id, test_category)
    end

    @tag :wip
    test "user set to a already categoried post fails", ~m(user post)a do
      test_category = "test category"
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _} = Accounts.set_favorites(user, :post, post.id, test_category)

      {:error, error} = Accounts.set_favorites(user, :post, post.id, test_category)
      assert error |> Keyword.get(:code) == ecode(:already_did)
    end

    test "user can set category to a unfavorited post fails", ~m(user post)a do
      {:error, _} = Accounts.set_favorites(user, :post, post.id, "test category")
    end

    @tag :wip
    test "user can unset category to a favorited post", ~m(user post)a do
      test_category = "test category"
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, test_category)
      assert {:ok, _} = CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      {:ok, _category} = Accounts.unset_favorites(user, :post, post.id, test_category)

      assert {:error, _} = CMS.PostFavorite |> ORM.find_by(%{post_id: post.id, user_id: user.id})
    end
  end

  describe "[favorite category total_count]" do
    @tag :wip
    test "total_count + 1 after set category to a favorited post", ~m(user post post2)a do
      test_category = "test category"
      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      assert category.total_count == 0

      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, test_category)

      {:ok, category} = FavoriteCategory |> ORM.find(category.id)
      assert category.total_count == 1

      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post2.id, test_category)
      {:ok, category} = FavoriteCategory |> ORM.find(category.id)

      assert category.total_count == 2
    end

    @tag :wip
    test "total_count - 1 after unset category to a favorited post", ~m(user post)a do
      test_category = "test category"
      {:ok, _category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, _post_favorite} = Accounts.set_favorites(user, :post, post.id, test_category)

      {:ok, category} = Accounts.unset_favorites(user, :post, post.id, test_category)

      assert category.total_count == 0
    end
  end
end
