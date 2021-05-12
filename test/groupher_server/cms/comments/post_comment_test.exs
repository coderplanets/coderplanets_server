defmodule GroupherServer.Test.CMS.Comments.PostComment do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}

  alias CMS.{ArticleComment, ArticlePinedComment, Embeds, Post}

  @delete_hint CMS.ArticleComment.delete_hint()
  @report_threshold_for_fold ArticleComment.report_threshold_for_fold()
  @default_comment_meta Embeds.ArticleCommentMeta.default_meta()
  @pined_comment_limit ArticleComment.pined_comment_limit()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)

    {:ok, ~m(user user2 post)a}
  end

  describe "[basic article comment]" do
    @tag :wip
    test "post are supported by article comment.", ~m(user post)a do
      {:ok, post_comment_1} = CMS.create_article_comment(:post, post.id, "post_comment 1", user)
      {:ok, post_comment_2} = CMS.create_article_comment(:post, post.id, "post_comment 2", user)

      {:ok, post} = ORM.find(Post, post.id, preload: :article_comments)

      assert exist_in?(post_comment_1, post.article_comments)
      assert exist_in?(post_comment_2, post.article_comments)
    end

    @tag :wip
    test "comment should have default meta after create", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "post comment", user)
      assert comment.meta |> Map.from_struct() |> Map.delete(:id) == @default_comment_meta
    end

    @tag :wip3
    test "comment can be updated", ~m(post user)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "post comment", user)

      {:ok, updated_comment} = CMS.update_article_comment(comment, "updated content")

      assert updated_comment.body_html == "updated content"
    end
  end

  describe "[article comment floor]" do
    @tag :wip
    test "comment will have a floor number after created", ~m(user post)a do
      {:ok, post_comment} = CMS.create_article_comment(:post, post.id, "comment", user)
      {:ok, post_comment2} = CMS.create_article_comment(:post, post.id, "comment2", user)

      {:ok, post_comment} = ORM.find(ArticleComment, post_comment.id)
      {:ok, post_comment2} = ORM.find(ArticleComment, post_comment2.id)

      assert post_comment.floor == 1
      assert post_comment2.floor == 2
    end
  end

  describe "[article comment participator for post]" do
    @tag :wip
    test "post will have participator after comment created", ~m(user post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)

      {:ok, post} = ORM.find(Post, post.id)

      participator = List.first(post.article_comments_participators)
      assert participator.id == user.id
    end

    @tag :wip
    test "psot participator will not contains same user", ~m(user post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)
      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)

      {:ok, post} = ORM.find(Post, post.id)

      assert 1 == length(post.article_comments_participators)
    end

    @tag :wip
    test "recent comment user should appear at first of the psot participators",
         ~m(user user2 post)a do
      post_comment_1 = "post_comment 1"

      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user)
      {:ok, _} = CMS.create_article_comment(:post, post.id, post_comment_1, user2)

      {:ok, post} = ORM.find(Post, post.id)

      participator = List.first(post.article_comments_participators)

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
    test "article author upvote post comment will have flag", ~m(post user)a do
      comment = "post_comment"
      {:ok, comment} = CMS.create_article_comment(:post, post.id, comment, user)
      {:ok, author_user} = ORM.find(Accounts.User, post.author.user.id)

      CMS.upvote_article_comment(comment.id, author_user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)
      assert comment.meta.is_article_author_upvoted
    end

    @tag :wip3
    test "user upvote post comment will add id to upvoted_user_ids", ~m(post user)a do
      comment = "post_comment"
      {:ok, comment} = CMS.create_article_comment(:post, post.id, comment, user)
      {:ok, comment} = CMS.upvote_article_comment(comment.id, user)

      assert user.id in comment.meta.upvoted_user_ids
    end

    @tag :wip3
    test "user undo upvote post comment will remove id from upvoted_user_ids",
         ~m(post user user2)a do
      comment = "post_comment"
      {:ok, comment} = CMS.create_article_comment(:post, post.id, comment, user)
      {:ok, _comment} = CMS.upvote_article_comment(comment.id, user)
      {:ok, comment} = CMS.upvote_article_comment(comment.id, user2)

      assert user2.id in comment.meta.upvoted_user_ids
      assert user.id in comment.meta.upvoted_user_ids

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user2)

      assert user.id in comment.meta.upvoted_user_ids
      assert user2.id not in comment.meta.upvoted_user_ids
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

    @tag :wip
    test "user can undo upvote a post comment", ~m(user post)a do
      content = "post_comment"
      {:ok, comment} = CMS.create_article_comment(:post, post.id, content, user)
      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    @tag :wip
    test "user can undo upvote a post comment with no upvote", ~m(user post)a do
      content = "post_comment"
      {:ok, comment} = CMS.create_article_comment(:post, post.id, content, user)
      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count
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

  describe "[article comment pin/unpin]" do
    test "user can pin a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_pinned

      {:ok, comment} = CMS.pin_article_comment(comment.id)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_pinned

      {:ok, pined_record} = ArticlePinedComment |> ORM.find_by(%{post_id: post.id})
      assert pined_record.post_id == post.id
    end

    test "user can unpin a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

      {:ok, _comment} = CMS.pin_article_comment(comment.id)
      {:ok, comment} = CMS.undo_pin_article_comment(comment.id)

      assert not comment.is_pinned
      assert {:error, _} = ArticlePinedComment |> ORM.find_by(%{article_comment_id: comment.id})
    end

    @tag :wip
    test "pined comments has a limit for each article", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

      Enum.reduce(0..(@pined_comment_limit - 1), [], fn _, _acc ->
        {:ok, _comment} = CMS.pin_article_comment(comment.id)
      end)

      assert {:error, _} = CMS.pin_article_comment(comment.id)
    end
  end

  describe "[article comment report/unreport]" do
    # @tag :wip
    # test "user can report a comment", ~m(user post)a do
    #   {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)

    #   {:ok, comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)
    # end

    # @tag :wip3
    # test "user can unreport a comment", ~m(user post)a do
    #   {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
    #   {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)

    #   {:ok, _comment} = CMS.undo_report_article_comment(comment.id, user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)
    # end

    @tag :wip3
    test "can undo a report with other user report it too",
         ~m(user user2 post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

      {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
      {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user2)

      filter = %{content_type: :article_comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))

      {:ok, _report} = CMS.undo_report_article(:article_comment, comment.id, user)

      filter = %{content_type: :article_comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.list_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
    end

    @tag :wip
    test "report user < @report_threshold_for_fold will not fold comment", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold - 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_article_comment(comment.id, "reason", "attr", user)
      end)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_folded
    end

    @tag :wip
    test "report user > @report_threshold_for_fold will cause comment fold", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

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
    @tag :wip
    test "can load paged comments participators of a article", ~m(user post)a do
      total_count = 30
      page_size = 10
      thread = :post

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, new_user} = db_insert(:user)
        {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", new_user)

        acc ++ [comment]
      end)

      {:ok, _comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _comment} = CMS.create_article_comment(:post, post.id, "commment", user)

      {:ok, results} =
        CMS.list_article_comments_participators(thread, post.id, %{page: 1, size: page_size})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == total_count + 1
    end

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
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size}, :replies)

      random_comment = all_comments |> Enum.at(Enum.random(0..total_count))

      assert not random_comment.is_folded

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end

    @tag :wip
    test "paged article comments should contains pined comments at top position",
         ~m(user post)a do
      total_count = 20
      page_number = 1
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_article_comment(:post, post.id, "pin commment", user)
      {:ok, random_comment_2} = CMS.create_article_comment(:post, post.id, "pin commment2", user)

      {:ok, pined_comment_1} = CMS.pin_article_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_article_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size}, :replies)

      assert pined_comment_1.id == List.first(paged_comments.entries) |> Map.get(:id)
      assert pined_comment_2.id == Enum.at(paged_comments.entries, 1) |> Map.get(:id)

      assert paged_comments.total_count == total_count + 2
    end

    @tag :wip
    test "only page 1 have pined coments",
         ~m(user post)a do
      total_count = 20
      page_number = 2
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_article_comment(:post, post.id, "pin commment", user)
      {:ok, random_comment_2} = CMS.create_article_comment(:post, post.id, "pin commment2", user)

      {:ok, pined_comment_1} = CMS.pin_article_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_article_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size}, :replies)

      assert not exist_in?(pined_comment_1, paged_comments.entries)
      assert not exist_in?(pined_comment_2, paged_comments.entries)

      assert paged_comments.total_count == total_count
    end

    @tag :wip3
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

      {:ok, _comment} = CMS.fold_article_comment(random_comment_1.id, user)
      {:ok, _comment} = CMS.fold_article_comment(random_comment_2.id, user)
      {:ok, _comment} = CMS.fold_article_comment(random_comment_3.id, user)

      {:ok, paged_comments} =
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size}, :replies)

      assert not exist_in?(random_comment_1, paged_comments.entries)
      assert not exist_in?(random_comment_2, paged_comments.entries)
      assert not exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count - 3 == paged_comments.total_count
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
  end

  describe "[article comment delete]" do
    @tag :wip3
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

      {:ok, deleted_comment} = CMS.delete_article_comment(random_comment)

      {:ok, paged_comments} =
        CMS.list_article_comments(:post, post.id, %{page: page_number, size: page_size}, :replies)

      assert exist_in?(deleted_comment, paged_comments.entries)
      assert deleted_comment.is_deleted
      assert deleted_comment.body_html == @delete_hint
    end

    @tag :wip3
    test "delete comment still update article's comments_count field", ~m(user post)a do
      {:ok, _comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      {:ok, _comment} = CMS.create_article_comment(:post, post.id, "commment", user)

      {:ok, post} = ORM.find(Post, post.id)

      assert post.article_comments_count == 5

      {:ok, _} = CMS.delete_article_comment(comment)

      {:ok, post} = ORM.find(Post, post.id)
      assert post.article_comments_count == 4
    end

    @tag :wip3
    test "delete comment still delete pined record if needed", ~m(user post)a do
      total_count = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, _comment} = CMS.pin_article_comment(random_comment.id)
      {:ok, _comment} = ORM.find(ArticleComment, random_comment.id)

      {:ok, _} = CMS.delete_article_comment(random_comment)
      assert {:error, _comment} = ORM.find(ArticlePinedComment, random_comment.id)
    end
  end

  describe "[article comment info]" do
    test "author of the article comment a comment should have flag", ~m(user post)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      assert not comment.is_article_author

      author_user = post.author.user
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", author_user)
      assert comment.is_article_author
    end
  end
end
