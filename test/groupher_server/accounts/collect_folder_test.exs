defmodule GroupherServer.Test.Accounts.CollectFolder do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  alias Accounts.{Embeds}
  alias Accounts.FavoriteCategory

  @default_meta Embeds.CollectFolderMeta.default_meta()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, post2} = db_insert(:post)

    {:ok, job} = db_insert(:job)

    {:ok, ~m(user user2 post post2 job)a}
  end

  describe "[collect folder curd]" do
    @tag :wip3
    test "user can create collect folder", ~m(user)a do
      folder_title = "test folder"

      args = %{title: folder_title, private: true, collects: []}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      assert folder.title == folder_title
      assert folder.user_id == user.id
      assert folder.private == true
      assert folder.meta |> Map.from_struct() |> Map.delete(:id) == @default_meta
    end

    @tag :wip3
    test "user create dup collect folder fails", ~m(user)a do
      {:ok, _category} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:error, reason} = Accounts.create_collect_folder(%{title: "test folder"}, user)

      assert reason |> is_error?(:already_exsit)
    end

    @tag :wip3
    test "user can get public collect-folder list", ~m(user)a do
      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, result} = Accounts.list_collect_folders(%{page: 1, size: 20}, user)

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 2
    end

    @tag :wip3
    test "user can get public collect-folder list by thread", ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, result} = Accounts.list_collect_folders(%{page: 1, size: 20, thread: :post}, user)

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 1

      assert result.entries |> List.first() |> Map.get(:id) == folder.id
    end

    @tag :wip3
    test "user can not get private folder list of other user", ~m(user user2)a do
      {:ok, _folder} =
        Accounts.create_collect_folder(%{title: "test folder", private: true}, user2)

      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user2)

      {:ok, result} = Accounts.list_collect_folders(%{page: 1, size: 20}, user2, user)

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 1
    end

    @tag :wip3
    test "collect creator can get both public and private folder list", ~m(user)a do
      {:ok, _folder} =
        Accounts.create_collect_folder(%{title: "test folder", private: true}, user)

      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)
      {:ok, result} = Accounts.list_collect_folders(%{page: 1, size: 20}, user, user)

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 2
    end

    @tag :wip3
    test "user can update a collect folder", ~m(user)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder", private: true}, user)

      args = %{id: folder.id, title: "new title", desc: "new desc"}
      {:ok, updated} = Accounts.update_collect_folder(args, user)

      assert updated.desc == "new desc"
      assert updated.title == "new title"

      {:ok, updated} = Accounts.update_collect_folder(%{id: folder.id, private: true}, user)
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

  describe "[add/remove from collect]" do
    @tag :wip3
    test "can add post to exsit colect-folder", ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)

      {:ok, folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      assert folder.total_count == 1
      assert folder.collects |> length == 1
      assert folder.collects |> List.first() |> Map.get(:post_id) == post.id
    end

    @tag :wip3
    test "can not collect some article in one collect-folder", ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:error, reason} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      assert reason |> is_error?(:already_collected_in_folder)
    end

    @tag :wip3
    test "colect-folder should in article_collect's meta info too", ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      collect_in_folder = folder.collects |> List.first()
      {:ok, article_collect} = ORM.find(CMS.ArticleCollect, collect_in_folder.id)
      article_collect_folder = article_collect.collect_folders |> List.first()
      assert article_collect_folder.id == folder.id
    end

    @tag :wip3
    test "one article collected in different collect-folder should only have one article-collect record",
         ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder2} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder2.id, user)

      {:ok, result} = ORM.find_all(CMS.ArticleCollect, %{page: 1, size: 10})
      article_collect = result.entries |> List.first()

      assert article_collect.post_id == post.id
      assert result.total_count == 1
    end

    @tag :wip3
    test "can remove post to exsit colect-folder", ~m(user post post2)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post2.id, folder.id, user)

      {:ok, _} = Accounts.remove_from_collect(:post, post.id, folder.id, user)

      {:ok, result} = Accounts.list_collect_folder_articles(folder.id, %{page: 1, size: 10}, user)

      assert result.total_count == 1
      assert result.entries |> length == 1
      assert result.entries |> List.first() |> Map.get(:id) == post2.id
    end

    @tag :wip3
    test "can remove post to exsit colect-folder should update article collect meta",
         ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder2} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder2.id, user)

      {:ok, _} = Accounts.remove_from_collect(:post, post.id, folder.id, user)

      {:ok, result} = ORM.find_all(CMS.ArticleCollect, %{page: 1, size: 10})

      article_collect =
        result.entries |> List.first() |> Map.get(:collect_folders) |> List.first()

      assert article_collect.id == folder2.id
    end

    @tag :wip3
    test "post belongs to other folder should keep article collect record",
         ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder2} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder2.id, user)

      {:ok, _} = Accounts.remove_from_collect(:post, post.id, folder.id, user)

      {:ok, result} = ORM.find_all(CMS.ArticleCollect, %{page: 1, size: 10})
      article_collect = result.entries |> List.first()

      assert article_collect.collect_folders |> length == 1

      {:ok, _} = Accounts.remove_from_collect(:post, post.id, folder.id, user)
      {:ok, result} = ORM.find_all(CMS.ArticleCollect, %{page: 1, size: 10})
      assert result.total_count == 0
    end

    @tag :wip2
    test "add post to exsit colect-folder should update meta", ~m(user post post2 job)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)

      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post2.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:job, job.id, folder.id, user)

      {:ok, folder} = Accounts.remove_from_collect(:post, post.id, folder.id, user)

      assert folder.meta.has_post
      assert folder.meta.has_job

      assert folder.meta.post_count == 1
      assert folder.meta.job_count == 1
    end

    @tag :wip2
    test "remove post to exsit colect-folder should update meta", ~m(user post post2 job)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post2.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:job, job.id, folder.id, user)

      {:ok, folder} = Accounts.remove_from_collect(:post, post.id, folder.id, user)
      assert folder.meta.has_post
      assert folder.meta.has_job

      {:ok, folder} = Accounts.remove_from_collect(:post, post2.id, folder.id, user)

      assert not folder.meta.has_post
      assert folder.meta.has_job

      {:ok, folder} = Accounts.remove_from_collect(:job, job.id, folder.id, user)

      assert not folder.meta.has_post
      assert not folder.meta.has_job
    end

    @tag :wip3
    test "can get articles of a collect folder", ~m(user post job)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:job, job.id, folder.id, user)

      {:ok, result} = Accounts.list_collect_folder_articles(folder.id, %{page: 1, size: 10}, user)
      assert result |> is_valid_pagination?(:raw)

      collect_job = result.entries |> List.first()
      collect_post = result.entries |> List.last()

      assert collect_job.id == job.id
      assert collect_job.title == job.title

      assert collect_post.id == post.id
      assert collect_post.title == post.title
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
