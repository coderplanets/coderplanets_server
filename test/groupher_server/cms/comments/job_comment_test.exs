defmodule GroupherServer.Test.CMS.Comments.JobComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  alias CMS.{ArticleComment, ArticlePinnedComment, Embeds, Job}

  @delete_hint CMS.ArticleComment.delete_hint()
  @report_threshold_for_fold ArticleComment.report_threshold_for_fold()
  @default_comment_meta Embeds.ArticleCommentMeta.default_meta()
  @pinned_comment_limit ArticleComment.pinned_comment_limit()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, job} = db_insert(:job)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(community user user2 job)a}
  end

  describe "[basic article comment]" do
    test "job are supported by article comment.", ~m(user job)a do
      {:ok, job_comment_1} = CMS.create_article_comment(:job, job.id, "job_comment 1", user)
      {:ok, job_comment_2} = CMS.create_article_comment(:job, job.id, "job_comment 2", user)

      {:ok, job} = ORM.find(Job, job.id, preload: :article_comments)

      assert exist_in?(job_comment_1, job.article_comments)
      assert exist_in?(job_comment_2, job.article_comments)
    end

    test "comment should have default meta after create", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "job comment", user)
      assert comment.meta |> Map.from_struct() |> Map.delete(:id) == @default_comment_meta
    end

    @tag :wip2
    test "create comment should update active timestamp of job", ~m(user job)a do
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "job comment", user)
      {:ok, job} = ORM.find(Job, job.id, preload: :article_comments)

      assert not is_nil(job.active_at)
      assert job.active_at > job.inserted_at
    end

    @tag :wip2
    test "job author create comment will not update active timestamp", ~m(community user)a do
      job_attrs = mock_attrs(:job, %{community_id: community.id})
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, job} = ORM.find(Job, job.id, preload: [author: :user])

      Process.sleep(1000)

      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "job comment", job.author.user)

      {:ok, job} = ORM.find(Job, job.id, preload: :article_comments)

      assert not is_nil(job.active_at)
      assert job.active_at == job.inserted_at
    end

    test "comment can be updated", ~m(job user)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "job comment", user)

      {:ok, updated_comment} = CMS.update_article_comment(comment, "updated content")

      assert updated_comment.body_html == "updated content"
    end
  end

  describe "[article comment floor]" do
    test "comment will have a floor number after created", ~m(user job)a do
      {:ok, job_comment} = CMS.create_article_comment(:job, job.id, "comment", user)
      {:ok, job_comment2} = CMS.create_article_comment(:job, job.id, "comment2", user)

      {:ok, job_comment} = ORM.find(ArticleComment, job_comment.id)
      {:ok, job_comment2} = ORM.find(ArticleComment, job_comment2.id)

      assert job_comment.floor == 1
      assert job_comment2.floor == 2
    end
  end

  describe "[article comment participator for job]" do
    test "job will have participator after comment created", ~m(user job)a do
      job_comment_1 = "job_comment 1"

      {:ok, _} = CMS.create_article_comment(:job, job.id, job_comment_1, user)

      {:ok, job} = ORM.find(Job, job.id)

      participator = List.first(job.article_comments_participators)
      assert participator.id == user.id
    end

    test "psot participator will not contains same user", ~m(user job)a do
      job_comment_1 = "job_comment 1"

      {:ok, _} = CMS.create_article_comment(:job, job.id, job_comment_1, user)
      {:ok, _} = CMS.create_article_comment(:job, job.id, job_comment_1, user)

      {:ok, job} = ORM.find(Job, job.id)

      assert 1 == length(job.article_comments_participators)
    end

    test "recent comment user should appear at first of the psot participators",
         ~m(user user2 job)a do
      job_comment_1 = "job_comment 1"

      {:ok, _} = CMS.create_article_comment(:job, job.id, job_comment_1, user)
      {:ok, _} = CMS.create_article_comment(:job, job.id, job_comment_1, user2)

      {:ok, job} = ORM.find(Job, job.id)

      participator = List.first(job.article_comments_participators)

      assert participator.id == user2.id
    end
  end

  describe "[article comment upvotes]" do
    test "user can upvote a job comment", ~m(user job)a do
      comment = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, comment, user)

      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    test "article author upvote job comment will have flag", ~m(job user)a do
      comment = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, comment, user)
      {:ok, author_user} = ORM.find(Accounts.User, job.author.user.id)

      CMS.upvote_article_comment(comment.id, author_user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)
      assert comment.meta.is_article_author_upvoted
    end

    test "user upvote job comment will add id to upvoted_user_ids", ~m(job user)a do
      comment = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, comment, user)
      {:ok, comment} = CMS.upvote_article_comment(comment.id, user)

      assert user.id in comment.meta.upvoted_user_ids
    end

    test "user undo upvote job comment will remove id from upvoted_user_ids",
         ~m(job user user2)a do
      comment = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, comment, user)
      {:ok, _comment} = CMS.upvote_article_comment(comment.id, user)
      {:ok, comment} = CMS.upvote_article_comment(comment.id, user2)

      assert user2.id in comment.meta.upvoted_user_ids
      assert user.id in comment.meta.upvoted_user_ids

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user2)

      assert user.id in comment.meta.upvoted_user_ids
      assert user2.id not in comment.meta.upvoted_user_ids
    end

    test "user upvote a already-upvoted comment fails", ~m(user job)a do
      comment = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, comment, user)

      CMS.upvote_article_comment(comment.id, user)
      {:error, _} = CMS.upvote_article_comment(comment.id, user)
    end

    test "upvote comment should inc the comment's upvotes_count", ~m(user user2 job)a do
      comment = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, comment, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.upvotes_count == 0

      {:ok, _} = CMS.upvote_article_comment(comment.id, user)
      {:ok, _} = CMS.upvote_article_comment(comment.id, user2)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.upvotes_count == 2
    end

    test "user can undo upvote a job comment", ~m(user job)a do
      content = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, content, user)
      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    test "user can undo upvote a job comment with no upvote", ~m(user job)a do
      content = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, content, user)
      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end
  end

  describe "[article comment fold/unfold]" do
    test "user can fold a comment", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_folded

      {:ok, comment} = CMS.fold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_folded
    end

    test "user can unfold a comment", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      {:ok, _comment} = CMS.fold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_folded

      {:ok, _comment} = CMS.unfold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_folded
    end
  end

  describe "[article comment pin/unpin]" do
    test "user can pin a comment", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_pinned

      {:ok, comment} = CMS.pin_article_comment(comment.id)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_pinned

      {:ok, pined_record} = ArticlePinnedComment |> ORM.find_by(%{job_id: job.id})
      assert pined_record.job_id == job.id
    end

    test "user can unpin a comment", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

      {:ok, _comment} = CMS.pin_article_comment(comment.id)
      {:ok, comment} = CMS.undo_pin_article_comment(comment.id)

      assert not comment.is_pinned
      assert {:error, _} = ArticlePinnedComment |> ORM.find_by(%{article_comment_id: comment.id})
    end

    test "pinned comments has a limit for each article", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

      Enum.reduce(0..(@pinned_comment_limit - 1), [], fn _, _acc ->
        {:ok, _comment} = CMS.pin_article_comment(comment.id)
      end)

      assert {:error, _} = CMS.pin_article_comment(comment.id)
    end
  end

  describe "[article comment report/unreport]" do
    #
    # test "user can report a comment", ~m(user job)a do
    #   {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)

    #   {:ok, comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)
    # end

    #
    # test "user can unreport a comment", ~m(user job)a do
    #   {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
    #   {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)

    #   {:ok, _comment} = CMS.undo_report_article_comment(comment.id, user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)
    # end

    test "can undo a report with other user report it too",
         ~m(user user2 job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

      {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
      {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user2)

      filter = %{content_type: :article_comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))

      {:ok, _report} = CMS.undo_report_article(:article_comment, comment.id, user)

      filter = %{content_type: :article_comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
    end

    test "report user < @report_threshold_for_fold will not fold comment", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold - 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
      end)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_folded
    end

    test "report user > @report_threshold_for_fold will cause comment fold", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold + 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
      end)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_folded
    end
  end

  describe "paged article comments" do
    test "can load paged comments participators of a article", ~m(user job)a do
      total_count = 30
      page_size = 10
      thread = :job

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, new_user} = db_insert(:user)
        {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", new_user)

        acc ++ [comment]
      end)

      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "commment", user)

      {:ok, results} =
        CMS.paged_article_comments_participators(thread, job.id, %{page: 1, size: page_size})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == total_count + 1
    end

    test "paged article comments folded flag should be false", ~m(user job)a do
      total_count = 30
      page_number = 1
      page_size = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

          acc ++ [comment]
        end)

      {:ok, paged_comments} =
        CMS.paged_article_comments(:job, job.id, %{page: page_number, size: page_size}, :replies)

      random_comment = all_comments |> Enum.at(Enum.random(0..total_count))

      assert not random_comment.is_folded

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end

    test "paged article comments should contains pinned comments at top position",
         ~m(user job)a do
      total_count = 20
      page_number = 1
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_article_comment(:job, job.id, "pin commment", user)
      {:ok, random_comment_2} = CMS.create_article_comment(:job, job.id, "pin commment2", user)

      {:ok, pined_comment_1} = CMS.pin_article_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_article_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_article_comments(:job, job.id, %{page: page_number, size: page_size}, :replies)

      assert pined_comment_1.id == List.first(paged_comments.entries) |> Map.get(:id)
      assert pined_comment_2.id == Enum.at(paged_comments.entries, 1) |> Map.get(:id)

      assert paged_comments.total_count == total_count + 2
    end

    test "only page 1 have pinned coments",
         ~m(user job)a do
      total_count = 20
      page_number = 2
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_article_comment(:job, job.id, "pin commment", user)
      {:ok, random_comment_2} = CMS.create_article_comment(:job, job.id, "pin commment2", user)

      {:ok, pined_comment_1} = CMS.pin_article_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_article_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_article_comments(:job, job.id, %{page: page_number, size: page_size}, :replies)

      assert not exist_in?(pined_comment_1, paged_comments.entries)
      assert not exist_in?(pined_comment_2, paged_comments.entries)

      assert paged_comments.total_count == total_count
    end

    test "paged article comments should not contains folded and repoted comments",
         ~m(user job)a do
      total_count = 15
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

          acc ++ [comment]
        end)

      random_comment_1 = all_comments |> Enum.at(0)
      random_comment_2 = all_comments |> Enum.at(1)
      random_comment_3 = all_comments |> Enum.at(3)

      {:ok, _comment} = CMS.fold_article_comment(random_comment_1.id, user)
      {:ok, _comment} = CMS.fold_article_comment(random_comment_2.id, user)
      {:ok, _comment} = CMS.fold_article_comment(random_comment_3.id, user)

      {:ok, paged_comments} =
        CMS.paged_article_comments(:job, job.id, %{page: page_number, size: page_size}, :replies)

      assert not exist_in?(random_comment_1, paged_comments.entries)
      assert not exist_in?(random_comment_2, paged_comments.entries)
      assert not exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count - 3 == paged_comments.total_count
    end

    test "can loaded paged folded comment", ~m(user job)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_folded_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
          CMS.fold_article_comment(comment.id, user)

          acc ++ [comment]
        end)

      random_comment_1 = all_folded_comments |> Enum.at(1)
      random_comment_2 = all_folded_comments |> Enum.at(3)
      random_comment_3 = all_folded_comments |> Enum.at(5)

      {:ok, paged_comments} =
        CMS.paged_folded_article_comments(:job, job.id, %{page: page_number, size: page_size})

      assert exist_in?(random_comment_1, paged_comments.entries)
      assert exist_in?(random_comment_2, paged_comments.entries)
      assert exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end
  end

  describe "[article comment delete]" do
    test "delete comment still exsit in paged list and content is gone", ~m(user job)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, deleted_comment} = CMS.delete_article_comment(random_comment)

      {:ok, paged_comments} =
        CMS.paged_article_comments(:job, job.id, %{page: page_number, size: page_size}, :replies)

      assert exist_in?(deleted_comment, paged_comments.entries)
      assert deleted_comment.is_deleted
      assert deleted_comment.body_html == @delete_hint
    end

    test "delete comment still update article's comments_count field", ~m(user job)a do
      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "commment", user)

      {:ok, job} = ORM.find(Job, job.id)

      assert job.article_comments_count == 5

      {:ok, _} = CMS.delete_article_comment(comment)

      {:ok, job} = ORM.find(Job, job.id)
      assert job.article_comments_count == 4
    end

    test "delete comment still delete pinned record if needed", ~m(user job)a do
      total_count = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, _comment} = CMS.pin_article_comment(random_comment.id)
      {:ok, _comment} = ORM.find(ArticleComment, random_comment.id)

      {:ok, _} = CMS.delete_article_comment(random_comment)
      assert {:error, _comment} = ORM.find(ArticlePinnedComment, random_comment.id)
    end
  end

  describe "[article comment info]" do
    test "author of the article comment a comment should have flag", ~m(user job)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
      assert not comment.is_article_author

      author_user = job.author.user
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", author_user)
      assert comment.is_article_author
    end
  end
end
