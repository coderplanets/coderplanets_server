defmodule GroupherServer.Test.Mutation.Accounts.CollectFolder do
  @moduledoc false
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  alias Accounts.CollectFolder

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, repo} = db_insert(:repo)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user post job repo)a}
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
    @tag :wip2
    test "login user can create collect folder", ~m(user_conn)a do
      variables = %{title: "test folder", desc: "cool folder"}
      created = user_conn |> mutation_result(@query, variables, "createCollectFolder")
      {:ok, found} = CollectFolder |> ORM.find(created |> Map.get("id"))

      assert created |> Map.get("id") == to_string(found.id)
      assert created["lastUpdated"] != nil
    end

    @tag :wip2
    test "login user can create private collect folder", ~m(user_conn)a do
      variables = %{title: "test folder", desc: "cool folder", private: true}
      created = user_conn |> mutation_result(@query, variables, "createCollectFolder")
      {:ok, found} = CollectFolder |> ORM.find(created |> Map.get("id"))

      assert created |> Map.get("id") == to_string(found.id)
      assert created |> Map.get("private")
    end

    @tag :wip2
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
    @tag :wip2
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
    @tag :wip2
    test "login user can delete own favorite category", ~m(user_conn user)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      variables = %{id: folder.id}
      user_conn |> mutation_result(@query, variables, "deleteCollectFolder")
      assert {:error, _} = CollectFolder |> ORM.find(folder.id)
    end
  end

  describe "[Accounts CollectFolder add/remove]" do
    @query """
    mutation($articleId: ID!, $folderId: ID!, $thread: CmsThread) {
      addToCollect(articleId: $articleId, folderId: $folderId, thread: $thread) {
        id
        title
        totalCount
        lastUpdated

        meta {
          hasPost
          hasJob
          hasRepo
          postCount
          jobCount
          repoCount
        }
      }
    }
    """
    @tag :wip2
    test "user can add a post to collect folder", ~m(user user_conn post)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)

      variables = %{articleId: post.id, folderId: folder.id, thread: "POST"}
      folder = user_conn |> mutation_result(@query, variables, "addToCollect")

      assert folder["totalCount"] == 1
      assert folder["lastUpdated"] != nil

      assert folder["meta"] == %{
               "hasJob" => false,
               "hasPost" => true,
               "hasRepo" => false,
               "jobCount" => 0,
               "postCount" => 1,
               "repoCount" => 0
             }

      {:ok, article_collect} =
        CMS.ArticleCollect |> ORM.find_by(%{post_id: post.id, user_id: user.id})

      folder_in_article_collect = article_collect.collect_folders |> List.first()

      assert folder_in_article_collect.meta.has_post
      assert folder_in_article_collect.meta.post_count == 1
    end

    @query """
    mutation($articleId: ID!, $folderId: ID!, $thread: CmsThread) {
      removeFromCollect(articleId: $articleId, folderId: $folderId, thread: $thread) {
        id
        title
        totalCount
        lastUpdated

        meta {
          hasPost
          hasJob
          hasRepo
          postCount
          jobCount
          repoCount
        }
      }
    }
    """
    @tag :wip2
    test "user can remove a post from collect folder", ~m(user user_conn post)a do
      args = %{title: "folder_title", private: false}
      {:ok, folder} = Accounts.create_collect_folder(args, user)
      {:ok, _folder} = Accounts.add_to_collect(:post, post.id, folder.id, user)

      variables = %{articleId: post.id, folderId: folder.id, thread: "POST"}
      result = user_conn |> mutation_result(@query, variables, "removeFromCollect")

      assert result["meta"] == %{
               "hasJob" => false,
               "hasPost" => false,
               "hasRepo" => false,
               "jobCount" => 0,
               "postCount" => 0,
               "repoCount" => 0
             }

      assert result["totalCount"] == 0
    end
  end
end
