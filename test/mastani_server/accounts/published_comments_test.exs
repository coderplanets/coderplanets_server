defmodule MastaniServer.Test.Accounts.PublishedComments do
  use MastaniServer.TestTools

  alias MastaniServer.{Accounts, CMS}

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, ~m(user user2)a}
  end

  describe "[Accounts Publised post comments]" do
    test "fresh user get empty paged published posts", ~m(user)a do
      {:ok, results} = Accounts.published_comments(user, :post, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published posts", ~m(user user2)a do
      body = "this is a test comment"
      {:ok, post} = db_insert(:post)
      {:ok, post2} = db_insert(:post)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"
          {:ok, comment} = CMS.create_comment(:post, post.id, body, user)
          acc ++ [comment]
        end)

      {:ok, _comment} = CMS.create_comment(:post, post2.id, body, user)
      {:ok, _comment} = CMS.create_comment(:post, post2.id, body, user2)

      {:ok, results} = Accounts.published_comments(user, :post, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count + 1

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_comment_id))
    end
  end

  describe "[Accounts Publised job comments]" do
    test "fresh user get empty paged published jobs", ~m(user)a do
      {:ok, results} = Accounts.published_comments(user, :job, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published jobs", ~m(user user2)a do
      body = "this is a test comment"
      {:ok, job} = db_insert(:job)
      {:ok, job2} = db_insert(:job)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"
          {:ok, comment} = CMS.create_comment(:job, job.id, body, user)
          acc ++ [comment]
        end)

      {:ok, _comment} = CMS.create_comment(:job, job2.id, body, user)
      {:ok, _comment} = CMS.create_comment(:job, job2.id, body, user2)

      {:ok, results} = Accounts.published_comments(user, :job, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count + 1

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_comment_id))
    end
  end

  describe "[Accounts Publised video comments]" do
    test "fresh user get empty paged published videos", ~m(user)a do
      {:ok, results} = Accounts.published_comments(user, :video, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published videos", ~m(user user2)a do
      body = "this is a test comment"
      {:ok, video} = db_insert(:video)
      {:ok, video2} = db_insert(:video)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"
          {:ok, comment} = CMS.create_comment(:video, video.id, body, user)
          acc ++ [comment]
        end)

      {:ok, _comment} = CMS.create_comment(:video, video2.id, body, user)
      {:ok, _comment} = CMS.create_comment(:video, video2.id, body, user2)

      {:ok, results} = Accounts.published_comments(user, :video, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count + 1

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_comment_id))
    end
  end

  describe "[Accounts Publised repo comments]" do
    test "fresh user get empty paged published repos", ~m(user)a do
      {:ok, results} = Accounts.published_comments(user, :repo, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published repos", ~m(user user2)a do
      body = "this is a test comment"
      {:ok, repo} = db_insert(:repo)
      {:ok, repo2} = db_insert(:repo)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"
          {:ok, comment} = CMS.create_comment(:repo, repo.id, body, user)
          acc ++ [comment]
        end)

      {:ok, _comment} = CMS.create_comment(:repo, repo2.id, body, user)
      {:ok, _comment} = CMS.create_comment(:repo, repo2.id, body, user2)

      {:ok, results} = Accounts.published_comments(user, :repo, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count + 1

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_comment_id))
    end
  end
end
