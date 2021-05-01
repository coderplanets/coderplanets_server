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

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.upvoted_articles(filter, user)

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

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.upvoted_articles(:post, filter, user)

      assert articles |> is_valid_pagination?(:raw)
      assert post.id == articles |> Map.get(:entries) |> List.last() |> Map.get(:id)
      assert 1 == articles |> Map.get(:total_count)
    end

    @tag :wip2
    test "user can get paged upvoted jobs by thread filter", ~m(user post job)a do
      {:ok, _} = CMS.upvote_article(:post, post.id, user)
      {:ok, _} = CMS.upvote_article(:job, job.id, user)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.upvoted_articles(:job, filter, user)

      assert articles |> is_valid_pagination?(:raw)
      assert job.id == articles |> Map.get(:entries) |> List.last() |> Map.get(:id)
      assert 1 == articles |> Map.get(:total_count)
    end
  end

  describe "[user stared contents]" do
    test "user can get paged stard_posts", ~m(user post)a do
      {:ok, _} = CMS.reaction(:post, :star, post.id, user)

      filter = %{page: 1, size: 20}
      {:ok, posts} = Accounts.reacted_contents(:post, :star, filter, user)
      assert posts |> is_valid_pagination?(:raw)
      assert post.id == posts |> Map.get(:entries) |> List.first() |> Map.get(:id)
    end

    test "user can get paged stared_jobs", ~m(user job)a do
      {:ok, _} = CMS.reaction(:job, :star, job.id, user)

      filter = %{page: 1, size: 20}
      {:ok, jobs} = Accounts.reacted_contents(:job, :star, filter, user)
      assert jobs |> is_valid_pagination?(:raw)
      assert job.id == jobs |> Map.get(:entries) |> List.first() |> Map.get(:id)
    end
  end
end
