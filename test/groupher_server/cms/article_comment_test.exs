defmodule GroupherServer.Test.CMS.ArticleComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{ArticleComment, Post}

  @delete_hint CMS.ArticleComment.delete_hint()
  @report_threshold_for_fold ArticleComment.report_threshold_for_fold()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user user2 post job)a}
  end

  describe "[basic article comment]" do
    @tag :wip
    test "post, job are supported by article comment.", ~m(user post job)a do
      post_comment_1 = "post_comment 1"
      post_comment_2 = "post_comment 2"
      job_comment_1 = "job_comment 1"
      job_comment_2 = "job_comment 2"

      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)
      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_2, user)

      {:ok, _} = CMS.create_article_comment(:job, job.id, job_comment_1, user)
      {:ok, _} = CMS.create_article_comment(:job, job.id, job_comment_2, user)

      {:ok, post} = ORM.find(Post, post.id, preload: :article_comments)
      {:ok, job} = ORM.find(Job, job.id, preload: :article_comments)

      assert List.first(post.article_comments).body_html == post_comment_1
      assert List.first(job.article_comments).body_html == job_comment_1
    end
  end

  describe "[article comment floor]" do
    @tag :wip
    test "comment will have a floor number after created", ~m(user post job)a do
      {:ok, _comment} = CMS.create_article_comment(:job, job.id, "comment", user)
      {:ok, job_comment} = CMS.create_article_comment(:job, job.id, "comment", user)
      {:ok, post_comment} = CMS.create_article_comment(:post, post.id, "comment", user)

      {:ok, post_comment} = ORM.find(ArticleComment, post_comment.id)
      {:ok, job_comment} = ORM.find(ArticleComment, job_comment.id)

      assert post_comment.floor == 1
      assert job_comment.floor == 2
    end
  end

  describe "[article comment participator]" do
    @tag :wip
    test "post will have participator after comment created", ~m(user post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)

      {:ok, post} = ORM.find(Post, post.id)

      participator = List.first(post.comment_participators)
      assert participator.id == user.id
    end

    @tag :wip
    test "psot participator will not contains same user", ~m(user post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)
      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)

      {:ok, post} = ORM.find(Post, post.id)

      assert 1 == length(post.comment_participators)
    end

    @tag :wip
    test "recent comment user should appear at first of the psot participators",
         ~m(user user2 post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)
      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user2)

      {:ok, post} = ORM.find(Post, post.id)

      participator = List.first(post.comment_participators)

      assert participator.id == user2.id
    end
  end

  describe "[article comment upvotes]" do
    @tag :wip
    test "user can upvote a post comment", ~m(user post)a do
      comment = "post_comment"
      {:ok, comment} = CMS.create_article_comment(:post, post.id, comment, user)

      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    @tag :wip
    test "user can upvote a job comment", ~m(user job)a do
      comment = "job_comment"
      {:ok, comment} = CMS.create_article_comment(:job, job.id, comment, user)

      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    @tag :wip
    test "user upvote a already-upvoted comment fails", ~m(user post)a do
      comment = "post_comment"
      {:ok, comment} = CMS.create_article_comment(:post, post.id, comment, user)

      CMS.upvote_article_comment(comment.id, user)
      {:error, _} = CMS.upvote_article_comment(comment.id, user)
    end

    @tag :wip
    test "upvote comment should inc the comment's upvotes_count", ~m(user user2 post)a do
      comment = "post_comment"
      {:ok, comment} = CMS.create_article_comment(:post, post.id, comment, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.upvotes_count == 0

      {:ok, _} = CMS.upvote_article_comment(comment.id, user)
      {:ok, _} = CMS.upvote_article_comment(comment.id, user2)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.upvotes_count == 2
    end
  end

  describe "[article comment fold/unfold]" do
    @tag :wip
    test "user can fold a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_folded

      {:ok, comment} = CMS.fold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_folded
    end

    @tag :wip
    test "user can unfold a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _comment} = CMS.fold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_folded

      {:ok, _comment} = CMS.unfold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_folded
    end
  end

  describe "[article comment report/unreport]" do
    @tag :wip
    test "user can report a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_reported

      {:ok, comment} = CMS.report_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_reported
    end

    @tag :wip
    test "user can unreport a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _comment} = CMS.report_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_reported

      {:ok, _comment} = CMS.unreport_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_reported
    end

    @tag :wip2
    test "report user < @report_threshold_for_fold will not fold comment", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

      assert not comment.is_reported
      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold - 1), [], fn _, acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_article_comment(comment.id, user)
      end)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_reported
      assert not comment.is_folded
    end

    @tag :wip2
    test "report user > @report_threshold_for_fold will cause comment fold", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

      assert not comment.is_reported
      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold + 1), [], fn _, acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_article_comment(comment.id, user)
      end)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_reported
      assert comment.is_folded
    end
  end

  describe "paged article comments" do
    @tag :wip
    test "paged article comments folded flag should be false", ~m(user post)a do
      total_count = 30
      page_number = 1
      page_size = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

          acc ++ [comment]
        end)

      {:ok, paged_comments} =
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size})

      random_comment = all_comments |> Enum.at(Enum.random(0..total_count))

      assert not random_comment.is_folded

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end

    @tag :wip
    test "paged article comments should not contains folded and repoted comments",
         ~m(user post)a do
      total_count = 15
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

          acc ++ [comment]
        end)

      random_comment_1 = all_comments |> Enum.at(0)
      random_comment_2 = all_comments |> Enum.at(1)
      random_comment_3 = all_comments |> Enum.at(3)

      random_comment_4 = all_comments |> Enum.at(2)
      random_comment_5 = all_comments |> Enum.at(4)
      random_comment_6 = all_comments |> Enum.at(8)

      {:ok, _comment} = CMS.fold_article_comment(random_comment_1.id, user)
      {:ok, _comment} = CMS.fold_article_comment(random_comment_2.id, user)
      {:ok, _comment} = CMS.fold_article_comment(random_comment_3.id, user)

      {:ok, _comment} = CMS.report_article_comment(random_comment_4.id, user)
      {:ok, _comment} = CMS.report_article_comment(random_comment_5.id, user)
      {:ok, _comment} = CMS.report_article_comment(random_comment_6.id, user)

      {:ok, paged_comments} =
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size})

      assert not exist_in?(random_comment_1, paged_comments.entries)
      assert not exist_in?(random_comment_2, paged_comments.entries)
      assert not exist_in?(random_comment_3, paged_comments.entries)

      assert not exist_in?(random_comment_4, paged_comments.entries)
      assert not exist_in?(random_comment_5, paged_comments.entries)
      assert not exist_in?(random_comment_6, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count - 6 == paged_comments.total_count
    end

    @tag :wip
    test "can loaded paged folded comment", ~m(user post)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_folded_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
          CMS.fold_article_comment(comment.id, user)

          acc ++ [comment]
        end)

      random_comment_1 = all_folded_comments |> Enum.at(1)
      random_comment_2 = all_folded_comments |> Enum.at(3)
      random_comment_3 = all_folded_comments |> Enum.at(5)

      {:ok, paged_comments} =
        CMS.list_folded_article_comments(:post, post.id, %{page: page_number, size: page_size})

      assert exist_in?(random_comment_1, paged_comments.entries)
      assert exist_in?(random_comment_2, paged_comments.entries)
      assert exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end

    @tag :wip
    test "can loaded paged reported comment", ~m(user post)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_reported_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
          CMS.report_article_comment(comment.id, user)

          acc ++ [comment]
        end)

      random_comment_1 = all_reported_comments |> Enum.at(1)
      random_comment_2 = all_reported_comments |> Enum.at(3)
      random_comment_3 = all_reported_comments |> Enum.at(5)

      {:ok, paged_comments} =
        CMS.list_reported_article_comments(:post, post.id, %{page: page_number, size: page_size})

      assert exist_in?(random_comment_1, paged_comments.entries)
      assert exist_in?(random_comment_2, paged_comments.entries)
      assert exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end
  end

  describe "[article comment delete]" do
    @tag :wip
    test "delete comment still exsit in paged list and content is gone", ~m(user post)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, deleted_comment} = CMS.delete_article_comment(random_comment.id, user)

      {:ok, paged_comments} =
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size})

      assert exist_in?(deleted_comment, paged_comments.entries)
      assert deleted_comment.is_deleted
      assert deleted_comment.body_html == @delete_hint
    end
  end

  describe "[article comment info]" do
    @tag :wip
    test "author of the article comment a comment should have flag", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      assert not comment.is_article_author

      {:ok, author_user} = db_insert(:user, %{id: post.author_id})
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", author_user)
      assert comment.is_article_author
    end
  end
end
