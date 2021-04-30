defmodule GroupherServer.Test.Mutation.ArticleCollect do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn post job user)a}
  end

  describe "[post collect]" do
    @query """
    mutation($id: ID!, $thread: CmsThread!) {
      collectArticle(id: $id, thread: $thread) {
        id
      }
    }
    """
    @tag :wip3
    test "login user can collect a post", ~m(user_conn post)a do
      variables = %{id: post.id, thread: "POST"}
      created = user_conn |> mutation_result(@query, variables, "collectArticle")

      assert created["id"] == to_string(post.id)
    end

    @tag :wip3
    test "unauth user collect a post fails", ~m(guest_conn post)a do
      variables = %{id: post.id, thread: "POST"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $thread: CmsThread!) {
      undoCollectArticle(id: $id, thread: $thread) {
        id
      }
    }
    """
    @tag :wip3
    test "login user can undo collect to a post", ~m(user_conn post user)a do
      {:ok, _} = CMS.collect_article(:post, post.id, user)

      variables = %{id: post.id, thread: "POST"}
      updated = user_conn |> mutation_result(@query, variables, "undoCollectArticle")

      assert updated["id"] == to_string(post.id)
    end

    @tag :wip3
    test "unauth user undo collect a post fails", ~m(guest_conn post)a do
      variables = %{id: post.id, thread: "POST"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end

  describe "[job collect]" do
    @query """
    mutation($id: ID!, $thread: CmsThread!) {
      collectArticle(id: $id, thread: $thread) {
        id
      }
    }
    """
    @tag :wip3
    test "login user can collect a job", ~m(user_conn job)a do
      variables = %{id: job.id, thread: "JOB"}
      created = user_conn |> mutation_result(@query, variables, "collectArticle")

      assert created["id"] == to_string(job.id)
    end

    @tag :wip3
    test "unauth user collect a job fails", ~m(guest_conn job)a do
      variables = %{id: job.id, thread: "JOB"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $thread: CmsThread!) {
      undoCollectArticle(id: $id, thread: $thread) {
        id
      }
    }
    """
    @tag :wip3
    test "login user can undo collect to a job", ~m(user_conn job user)a do
      {:ok, _} = CMS.collect_article(:job, job.id, user)

      variables = %{id: job.id, thread: "JOB"}
      updated = user_conn |> mutation_result(@query, variables, "undoCollectArticle")

      assert updated["id"] == to_string(job.id)
    end

    @tag :wip3
    test "unauth user undo collect a job fails", ~m(guest_conn job)a do
      variables = %{id: job.id, thread: "JOB"}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
