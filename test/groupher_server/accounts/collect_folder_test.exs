defmodule GroupherServer.Test.Accounts.CollectFolder do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  alias CMS.Model.ArticleCollect
  alias Accounts.Model.{Embeds}

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
    test "user can create collect folder", ~m(user)a do
      folder_title = "test folder"

      args = %{title: folder_title, private: true, collects: []}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      assert folder.title == folder_title
      assert folder.user_id == user.id
      assert folder.private == true
      assert folder.meta |> Map.from_struct() |> Map.delete(:id) == @default_meta
    end

    test "user create dup collect folder fails", ~m(user)a do
      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:error, reason} = Accounts.create_collect_folder(%{title: "test folder"}, user)

      assert reason |> is_error?(:already_exsit)
    end

    test "user can delete a empty collect folder", ~m(user)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _} = Accounts.delete_collect_folder(folder.id)

      assert {:error, _} = ORM.find(ArticleCollect, folder.id)
    end

    test "user can not delete a non-empty collect folder", ~m(post user)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      {:error, reason} = Accounts.delete_collect_folder(folder.id)

      assert reason |> is_error?(:delete_no_empty_collect_folder)
    end

    test "user can get public collect-folder list", ~m(user)a do
      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, result} = Accounts.paged_collect_folders(user.id, %{page: 1, size: 20})

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 2
    end

    test "user can get public collect-folder list by thread", ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      {:ok, result} = Accounts.paged_collect_folders(user.id, %{thread: :post, page: 1, size: 20})

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 1

      assert result.entries |> List.first() |> Map.get(:id) == folder.id
    end

    test "user can not get private folder list of other user", ~m(user user2)a do
      {:ok, _folder} =
        Accounts.create_collect_folder(%{title: "test folder", private: true}, user2)

      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user2)

      {:ok, result} = Accounts.paged_collect_folders(user2.id, %{page: 1, size: 20}, user)

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 1
    end

    test "collect creator can get both public and private folder list", ~m(user)a do
      {:ok, _folder} =
        Accounts.create_collect_folder(%{title: "test folder", private: true}, user)

      {:ok, _folder} = Accounts.create_collect_folder(%{title: "test folder2"}, user)
      {:ok, result} = Accounts.paged_collect_folders(user.id, %{page: 1, size: 20}, user)

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 2
    end

    test "user can update a collect folder", ~m(user)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder", private: true}, user)

      args = %{title: "new title", desc: "new desc"}
      {:ok, updated} = Accounts.update_collect_folder(folder.id, args)

      assert updated.desc == "new desc"
      assert updated.title == "new title"

      {:ok, updated} = Accounts.update_collect_folder(folder.id, %{private: true})
      assert updated.private == true
    end
  end

  describe "[add/remove from collect]" do
    test "can add post to exsit colect-folder", ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)

      {:ok, folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      assert folder.total_count == 1
      assert folder.collects |> length == 1
      assert folder.collects |> List.first() |> Map.get(:post_id) == post.id
    end

    test "can not collect some article in one collect-folder", ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:error, reason} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      assert reason |> is_error?(:already_collected_in_folder)
    end

    test "colect-folder should in article_collect's meta info too", ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      collect_in_folder = folder.collects |> List.first()
      {:ok, article_collect} = ORM.find(ArticleCollect, collect_in_folder.id)
      article_collect_folder = article_collect.collect_folders |> List.first()
      assert article_collect_folder.id == folder.id
    end

    test "one article collected in different collect-folder should only have one article-collect record",
         ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder2} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder2.id, user)

      {:ok, result} = ORM.find_all(ArticleCollect, %{page: 1, size: 10})
      article_collect = result.entries |> List.first()

      assert article_collect.post_id == post.id
      assert result.total_count == 1
    end

    test "can remove post to exsit colect-folder", ~m(user post post2)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post2.id, folder.id, user)

      {:ok, _} = Accounts.remove_from_collect(:post, post.id, folder.id, user)

      {:ok, result} =
        Accounts.paged_collect_folder_articles(folder.id, %{page: 1, size: 10}, user)

      assert result.total_count == 1
      assert result.entries |> length == 1
      assert result.entries |> List.first() |> Map.get(:id) == post2.id
    end

    test "can remove post to exsit colect-folder should update article collect meta",
         ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder2} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder2.id, user)

      {:ok, _} = Accounts.remove_from_collect(:post, post.id, folder.id, user)

      {:ok, result} = ORM.find_all(ArticleCollect, %{page: 1, size: 10})

      article_collect =
        result.entries |> List.first() |> Map.get(:collect_folders) |> List.first()

      assert article_collect.id == folder2.id
    end

    test "post belongs to other folder should keep article collect record",
         ~m(user post)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, folder2} = Accounts.create_collect_folder(%{title: "test folder2"}, user)

      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder2.id, user)

      {:ok, _} = Accounts.remove_from_collect(:post, post.id, folder.id, user)

      {:ok, result} = ORM.find_all(ArticleCollect, %{page: 1, size: 10})
      article_collect = result.entries |> List.first()

      assert article_collect.collect_folders |> length == 1

      {:ok, _} = Accounts.remove_from_collect(:post, post.id, folder.id, user)
      {:ok, result} = ORM.find_all(ArticleCollect, %{page: 1, size: 10})
      assert result.total_count == 0
    end

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

    test "can get articles of a collect folder", ~m(user post job)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder"}, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:job, job.id, folder.id, user)

      {:ok, result} =
        Accounts.paged_collect_folder_articles(folder.id, %{page: 1, size: 10}, user)

      assert result |> is_valid_pagination?(:raw)

      collect_job = result.entries |> List.first()
      collect_post = result.entries |> List.last()

      assert collect_job.id == job.id
      assert collect_job.title == job.title

      assert collect_post.id == post.id
      assert collect_post.title == post.title
    end

    test "can not get articles of a private collect folder if not owner",
         ~m(user user2 post job)a do
      {:ok, folder} = Accounts.create_collect_folder(%{title: "test folder", private: true}, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)
      {:ok, _folder} = Accounts.add_to_collect(:job, job.id, folder.id, user)

      {:ok, result} =
        Accounts.paged_collect_folder_articles(folder.id, %{page: 1, size: 10}, user)

      assert result |> is_valid_pagination?(:raw)

      {:error, reason} =
        Accounts.paged_collect_folder_articles(folder.id, %{page: 1, size: 10}, user2)

      assert reason |> is_error?(:private_collect_folder)
    end
  end
end
