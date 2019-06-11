defmodule GroupherServer.Test.Accounts.ReactedContents do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, video} = db_insert(:video)

    {:ok, ~m(user post job video)a}
  end

  describe "[user favorited  contents]" do
    test "user can get paged favorited_posts", ~m(user post)a do
      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)

      filter = %{page: 1, size: 20}
      {:ok, posts} = Accounts.reacted_contents(:post, :favorite, filter, user)
      assert posts |> is_valid_pagination?(:raw)
      assert post.id == posts |> Map.get(:entries) |> List.first() |> Map.get(:id)
    end

    test "user can get paged favorited_jobs", ~m(user job)a do
      {:ok, _} = CMS.reaction(:job, :favorite, job.id, user)

      filter = %{page: 1, size: 20}
      {:ok, jobs} = Accounts.reacted_contents(:job, :favorite, filter, user)
      assert jobs |> is_valid_pagination?(:raw)
      assert job.id == jobs |> Map.get(:entries) |> List.first() |> Map.get(:id)
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

    test "user can get paged stared_videos", ~m(user video)a do
      {:ok, _} = CMS.reaction(:video, :star, video.id, user)

      filter = %{page: 1, size: 20}
      {:ok, jobs} = Accounts.reacted_contents(:video, :star, filter, user)
      assert jobs |> is_valid_pagination?(:raw)
      assert video.id == jobs |> Map.get(:entries) |> List.first() |> Map.get(:id)
    end
  end
end
