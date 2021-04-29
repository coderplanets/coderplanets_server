defmodule GroupherServer.Test.CMS.ArticlePin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{
    Community,
    PinnedArticle
    # Post,
    # Job
  }

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, post} = CMS.create_content(community, :post, mock_attrs(:post), user)
    {:ok, job} = CMS.create_content(community, :job, mock_attrs(:job), user)
    {:ok, repo} = CMS.create_content(community, :repo, mock_attrs(:repo), user)

    {:ok, ~m(user community post job repo)a}
  end

  describe "[cms post pin]" do
    @tag :wip
    test "can pin a post", ~m(community post)a do
      {:ok, _} = CMS.pin_article(:post, post.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{post_id: post.id})

      assert pind_article.post_id == post.id
    end

    @tag :wip
    test "one community & thread can only pin certern count of post", ~m(community post user)a do
      {:ok, post2} = CMS.create_content(community, :post, mock_attrs(:post), user)
      {:ok, post3} = CMS.create_content(community, :post, mock_attrs(:post), user)

      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, _} = CMS.pin_article(:post, post.id, community.id)
        acc
      end)

      {:error, reason} = CMS.pin_article(:post, post3.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    @tag :wip
    test "can not pin a non-exsit post", ~m(community post)a do
      assert {:error, _} = CMS.pin_article(:post, 8848, community.id)
    end

    @tag :wip
    test "can undo pin to a post", ~m(community post)a do
      {:ok, _} = CMS.pin_article(:post, post.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:post, post.id, community.id)
      assert unpinned.post_id == post.id

      assert {:error, _} = ORM.find_by(PinnedArticle, %{post_id: post.id})
    end
  end

  # TODO: Job, Repo
end
