defmodule GroupherServer.Test.Accounts.ReactedContents do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user post job)a}
  end

  describe "[user upvoted articles]" do
    @tag :wip2
    test "user can get paged upvoted common articles", ~m(user post job)a do
      {:ok, _} = CMS.upvote_article(:post, post.id, user)
      {:ok, _} = CMS.upvote_article(:job, job.id, user)

      filter = %{user_id: user.id, page: 1, size: 20}
      {:ok, articles} = Accounts.list_upvoted_articles(filter)

      article_post = articles |> Map.get(:entries) |> List.last()
      article_job = articles |> Map.get(:entries) |> List.first()

      assert articles |> is_valid_pagination?(:raw)
      assert job.id == article_job |> Map.get(:id)
      assert post.id == article_post |> Map.get(:id)

      assert [:id, :thread, :title, :upvotes_count] == article_post |> Map.keys()
      assert [:id, :thread, :title, :upvotes_count] == article_job |> Map.keys()
    end

    @tag :wip2
    test "user can get paged upvoted posts by thread filter", ~m(user post job)a do
      {:ok, _} = CMS.upvote_article(:post, post.id, user)
      {:ok, _} = CMS.upvote_article(:job, job.id, user)

      filter = %{thread: :post, user_id: user.id, page: 1, size: 20}
      {:ok, articles} = Accounts.list_upvoted_articles(filter)

      assert articles |> is_valid_pagination?(:raw)
      assert post.id == articles |> Map.get(:entries) |> List.last() |> Map.get(:id)
      assert 1 == articles |> Map.get(:total_count)
    end

    @tag :wip2
    test "user can get paged upvoted jobs by thread filter", ~m(user post job)a do
      {:ok, _} = CMS.upvote_article(:post, post.id, user)
      {:ok, _} = CMS.upvote_article(:job, job.id, user)

      filter = %{thread: :job, user_id: user.id, page: 1, size: 20}
      {:ok, articles} = Accounts.list_upvoted_articles(filter)

      assert articles |> is_valid_pagination?(:raw)
      assert job.id == articles |> Map.get(:entries) |> List.last() |> Map.get(:id)
      assert 1 == articles |> Map.get(:total_count)
    end
  end
end
