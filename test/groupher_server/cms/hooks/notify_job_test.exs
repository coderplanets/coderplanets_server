defmodule GroupherServer.Test.CMS.Hooks.NotifyJob do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery}
  alias CMS.Delegate.Hooks

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})
    {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
    {:ok, comment} = CMS.create_comment(:job, job.id, mock_comment(), user)

    {:ok, ~m(user2 job comment)a}
  end

  describe "[upvote notify]" do
    @tag :wip2
    test "upvote hook should work on job", ~m(user2 job)a do
      {:ok, job} = preload_author(job)

      {:ok, article} = CMS.upvote_article(:job, job.id, user2)
      Hooks.Notify.handle(:upvote, article, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, job.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "UPVOTE"
      assert notify.article_id == job.id
      assert notify.type == "JOB"
      assert notify.user_id == job.author.user.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip2
    test "upvote hook should work on job comment", ~m(user2 job comment)a do
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)
      {:ok, comment} = preload_author(comment)

      Hooks.Notify.handle(:upvote, comment, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, comment.author.id, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "UPVOTE"
      assert notify.article_id == job.id
      assert notify.type == "COMMENT"
      assert notify.user_id == comment.author.id
      assert notify.comment_id == comment.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip2
    test "undo upvote hook should work on job", ~m(user2 job)a do
      {:ok, job} = preload_author(job)

      {:ok, article} = CMS.upvote_article(:job, job.id, user2)
      Hooks.Notify.handle(:upvote, article, user2)

      {:ok, article} = CMS.undo_upvote_article(:job, job.id, user2)
      Hooks.Notify.handle(:undo, :upvote, article, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, job.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end

    @tag :wip2
    test "undo upvote hook should work on job comment", ~m(user2 comment)a do
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)

      Hooks.Notify.handle(:upvote, comment, user2)

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user2)
      Hooks.Notify.handle(:undo, :upvote, comment, user2)

      {:ok, comment} = preload_author(comment)

      {:ok, notifications} =
        Delivery.fetch(:notification, comment.author.id, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end
  end

  describe "[collect notify]" do
    @tag :wip
    test "collect hook should work on job", ~m(user2 job)a do
      {:ok, job} = preload_author(job)

      {:ok, _} = CMS.collect_article(:job, job.id, user2)
      Hooks.Notify.handle(:collect, job, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, job.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "COLLECT"
      assert notify.article_id == job.id
      assert notify.type == "JOB"
      assert notify.user_id == job.author.user.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip
    test "undo collect hook should work on job", ~m(user2 job)a do
      {:ok, job} = preload_author(job)

      {:ok, _} = CMS.upvote_article(:job, job.id, user2)
      Hooks.Notify.handle(:collect, job, user2)

      {:ok, _} = CMS.undo_upvote_article(:job, job.id, user2)
      Hooks.Notify.handle(:undo, :collect, job, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, job.author.user.id, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end
  end
end
