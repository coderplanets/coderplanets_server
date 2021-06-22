defmodule GroupherServer.Test.CMS.Hooks.MentionInJob do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, job} = db_insert(:job)

    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community job job_attrs)a}
  end

  describe "[mention in job basic]" do
    test "mention multi user in job should work", ~m(user user2 user3 community  job_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>, and <div class=#{
            @article_mention_class
          }>#{user3.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      job_attrs = job_attrs |> Map.merge(%{body: body})
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, job} = preload_author(job)

      {:ok, _result} = Hooks.Mention.handle(job)

      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "JOB"
      assert mention.block_linker |> length == 2
      assert mention.article_id == job.id
      assert mention.title == job.title
      assert mention.user.login == job.author.user.login

      {:ok, result} = Delivery.fetch(:mention, user3, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "JOB"
      assert mention.block_linker |> length == 1
      assert mention.article_id == job.id
      assert mention.title == job.title
      assert mention.user.login == job.author.user.login
    end

    test "mention in job's comment should work", ~m(user user2 job)a do
      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>))

      {:ok, comment} = CMS.create_comment(:job, job.id, comment_body, user)
      {:ok, comment} = preload_author(comment)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.thread == "JOB"
      assert mention.comment_id == comment.id
      assert mention.block_linker |> length == 1
      assert mention.article_id == job.id
      assert mention.title == job.title
      assert mention.user.login == comment.author.login
    end

    test "can not mention author self in job or comment", ~m(community user job_attrs)a do
      body = mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))
      job_attrs = job_attrs |> Map.merge(%{body: body})
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})
      assert result.total_count == 0

      comment_body =
        mock_rich_text(~s(hi <div class=#{@article_mention_class}>#{user.login}</div>))

      {:ok, comment} = CMS.create_comment(:job, job.id, comment_body, user)

      {:ok, _result} = Hooks.Mention.handle(comment)
      {:ok, result} = Delivery.fetch(:mention, user, %{page: 1, size: 10})

      assert result.total_count == 0
    end
  end
end
