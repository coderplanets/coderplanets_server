defmodule GroupherServer.Test.Mutation.Accounts.CollectFolder do
  @moduledoc false
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.CollectFolder
  alias CMS.Model.ArticleCollect

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, repo} = db_insert(:repo)
    {:ok, blog} = db_insert(:blog)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user post job repo blog)a}
  end

  describe "[Accounts CollectFolder CURD]" do
    @query """
    mutation($title: String!, $desc: String, $private: Boolean) {
      createCollectFolder(title: $title, desc: $desc, private: $private) {
        id
        title
        private
        lastUpdated
      }
    }
    """

    test "login user can create collect folder", ~m(user_conn)a do
      variables = %{title: "test folder", desc: "cool folder"}
      created = user_conn |> mutation_result(@query, variables, "createCollectFolder")
      {:ok, found} = CollectFolder |> ORM.find(created |> Map.get("id"))

      assert created |> Map.get("id") == to_string(found.id)
      assert created["lastUpdated"] != nil
    end

    test "login user can create private collect folder", ~m(user_conn)a do
      variables = %{title: "test folder", desc: "cool folder", private: true}
      created = user_conn |> mutation_result(@query, variables, "createCollectFolder")
      {:ok, found} = CollectFolder |> ORM.find(created |> Map.get("id"))

      assert created |> Map.get("id") == to_string(found.id)
      assert created |> Map.get("private")
    end

    test "unauth user create category fails", ~m(guest_conn)a do
      variables = %{title: "test folder"}
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $title: String, $desc: String, $private: Boolean) {
      updateCollectFolder(
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
    test "login user can update own collect folder", ~m(user_conn user)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      variables = %{id: folder.id, title: "new title", desc: "new desc", private: true}
      updated = user_conn |> mutation_result(@query, variables, "updateCollectFolder")

      assert updated["desc"] == "new desc"
      assert updated["private"] == true
      assert updated["title"] == "new title"
      assert updated["lastUpdated"] != nil
    end

    @query """
    mutation($id: ID!) {
      deleteCollectFolder(id: $id) {
        id
      }
    }
    """
    test "login user can delete own collect folder", ~m(user_conn user)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      variables = %{id: folder.id}
      user_conn |> mutation_result(@query, variables, "deleteCollectFolder")
      assert {:error, _} = CollectFolder |> ORM.find(folder.id)
    end
  end

  describe "[Accounts CollectFolder add/remove]" do
    @query """
    mutation($articleId: ID!, $folderId: ID!, $thread: Thread) {
      addToCollect(articleId: $articleId, folderId: $folderId, thread: $thread) {
        id
        title
        totalCount
        lastUpdated

        meta {
          hasPost
          hasJob
          hasRepo
          hasBlog
          postCount
          jobCount
          repoCount
          blogCount
        }
      }
    }
    """
    @meta %{
      "hasJob" => false,
      "hasPost" => false,
      "hasRepo" => false,
      "hasBlog" => false,
      "jobCount" => 0,
      "postCount" => 0,
      "repoCount" => 0,
      "blogCount" => 0
    }
    test "user can add a post to collect folder", ~m(user user_conn post)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      variables = %{articleId: post.id, folderId: folder.id, thread: "POST"}
      folder = user_conn |> mutation_result(@query, variables, "addToCollect")

      assert folder["totalCount"] == 1
      assert folder["lastUpdated"] != nil

      assert folder["meta"] == @meta |> Map.merge(%{"hasPost" => true, "postCount" => 1})

      {:ok, article_collect} =
        ArticleCollect |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      folder_in_article_collect = article_collect.collect_folders |> List.first()

      assert folder_in_article_collect.meta.has_post
      assert folder_in_article_collect.meta.post_count == 1
    end

    test "user can add a job to collect folder", ~m(user user_conn job)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      variables = %{articleId: job.id, folderId: folder.id, thread: "JOB"}
      folder = user_conn |> mutation_result(@query, variables, "addToCollect")

      assert folder["totalCount"] == 1
      assert folder["lastUpdated"] != nil

      assert folder["meta"] == @meta |> Map.merge(%{"hasJob" => true, "jobCount" => 1})

      {:ok, article_collect} = ArticleCollect |> ORM.find_by(%{job_id: job.id, user_id: user.id})

      folder_in_article_collect = article_collect.collect_folders |> List.first()

      assert folder_in_article_collect.meta.has_job
      assert folder_in_article_collect.meta.job_count == 1
    end

    test "user can add a repo to collect folder", ~m(user user_conn repo)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      variables = %{articleId: repo.id, folderId: folder.id, thread: "REPO"}
      folder = user_conn |> mutation_result(@query, variables, "addToCollect")

      assert folder["totalCount"] == 1
      assert folder["lastUpdated"] != nil

      assert folder["meta"] == @meta |> Map.merge(%{"hasRepo" => true, "repoCount" => 1})

      {:ok, article_collect} =
        ArticleCollect |> ORM.find_by(%{repo_id: repo.id, user_id: user.id})

      folder_in_article_collect = article_collect.collect_folders |> List.first()

      assert folder_in_article_collect.meta.has_repo
      assert folder_in_article_collect.meta.repo_count == 1
    end

    test "user can add a blog to collect folder", ~m(user user_conn blog)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      variables = %{articleId: blog.id, folderId: folder.id, thread: "BLOG"}
      folder = user_conn |> mutation_result(@query, variables, "addToCollect")

      assert folder["totalCount"] == 1
      assert folder["lastUpdated"] != nil

      assert folder["meta"] == @meta |> Map.merge(%{"hasBlog" => true, "blogCount" => 1})

      {:ok, article_collect} =
        ArticleCollect |> ORM.find_by(%{blog_id: blog.id, user_id: user.id})

      folder_in_article_collect = article_collect.collect_folders |> List.first()

      assert folder_in_article_collect.meta.has_blog
      assert folder_in_article_collect.meta.blog_count == 1
    end

    @query """
    mutation($articleId: ID!, $folderId: ID!, $thread: Thread) {
      removeFromCollect(articleId: $articleId, folderId: $folderId, thread: $thread) {
        id
        title
        totalCount
        lastUpdated

        meta {
          hasPost
          hasJob
          hasRepo
          hasBlog
          postCount
          jobCount
          repoCount
          blogCount
        }
      }
    }
    """
    test "user can remove a post from collect folder", ~m(user user_conn post)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      variables = %{articleId: post.id, folderId: folder.id, thread: "POST"}
      result = user_conn |> mutation_result(@query, variables, "removeFromCollect")

      assert result["meta"] == @meta
      assert result["totalCount"] == 0
    end

    test "user can remove a job from collect folder", ~m(user user_conn job)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)
      {:ok, _folder} = Accounts.add_to_collect(:job, job.id, folder.id, user)

      variables = %{articleId: job.id, folderId: folder.id, thread: "JOB"}
      result = user_conn |> mutation_result(@query, variables, "removeFromCollect")

      assert result["meta"] == @meta
      assert result["totalCount"] == 0
    end

    test "user can remove a repo from collect folder", ~m(user user_conn repo)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)
      {:ok, _folder} = Accounts.add_to_collect(:repo, repo.id, folder.id, user)

      variables = %{articleId: repo.id, folderId: folder.id, thread: "REPO"}
      result = user_conn |> mutation_result(@query, variables, "removeFromCollect")

      assert result["meta"] == @meta
      assert result["totalCount"] == 0
    end

    test "user can remove a blog from collect folder", ~m(user user_conn blog)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)
      {:ok, _folder} = Accounts.add_to_collect(:blog, blog.id, folder.id, user)

      variables = %{articleId: blog.id, folderId: folder.id, thread: "BLOG"}
      result = user_conn |> mutation_result(@query, variables, "removeFromCollect")

      assert result["meta"] == @meta
      assert result["totalCount"] == 0
    end
  end
end
