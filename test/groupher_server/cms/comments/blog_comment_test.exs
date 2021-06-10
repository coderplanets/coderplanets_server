defmodule GroupherServer.Test.CMS.Comments.BlogComment do
  @moduledoc false

  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias CMS.Model.{ArticleComment, ArticlePinnedComment, Embeds, Blog}

  @active_period get_config(:article, :active_period_days)

  @delete_hint ArticleComment.delete_hint()
  @report_threshold_for_fold ArticleComment.report_threshold_for_fold()
  @default_comment_meta Embeds.ArticleCommentMeta.default_meta()
  @pinned_comment_limit ArticleComment.pinned_comment_limit()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, blog} = db_insert(:blog)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(community user user2 blog)a}
  end

  describe "[basic article comment]" do
    test "blog are supported by article comment.", ~m(user blog)a do
      {:ok, blog_comment_1} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, blog_comment_2} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :article_comments)

      assert exist_in?(blog_comment_1, blog.article_comments)
      assert exist_in?(blog_comment_2, blog.article_comments)
    end

    test "comment should have default meta after create", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      assert comment.meta |> Map.from_struct() |> Map.delete(:id) == @default_comment_meta
    end

    test "create comment should update active timestamp of blog", ~m(user blog)a do
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, blog} = ORM.find(Blog, blog.id, preload: :article_comments)

      assert not is_nil(blog.active_at)
      assert blog.active_at > blog.inserted_at
    end

    test "blog author create comment will not update active timestamp", ~m(community user)a do
      blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, blog} = ORM.find(Blog, blog.id, preload: [author: :user])

      Process.sleep(1000)

      {:ok, _comment} =
        CMS.create_article_comment(:blog, blog.id, mock_comment(), blog.author.user)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :article_comments)

      assert not is_nil(blog.active_at)
      assert blog.active_at == blog.inserted_at
    end

    test "old blog will not update active after comment created", ~m(user)a do
      active_period_days = Map.get(@active_period, :blog)

      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days - 1)) |> Timex.to_datetime()

      {:ok, blog} = db_insert(:blog, %{inserted_at: inserted_at})
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, blog} = ORM.find(Blog, blog.id)

      assert blog.active_at |> DateTime.to_date() == DateTime.utc_now() |> DateTime.to_date()

      #####
      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days + 1)) |> Timex.to_datetime()

      {:ok, blog} = db_insert(:blog, %{inserted_at: inserted_at})
      Process.sleep(3000)
      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, blog} = ORM.find(Blog, blog.id)

      assert blog.active_at |> DateTime.to_unix() !== DateTime.utc_now() |> DateTime.to_unix()
    end

    test "comment can be updated", ~m(blog user)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, updated_comment} =
        CMS.update_article_comment(comment, mock_comment("updated content"))

      assert updated_comment.body_html |> String.contains?(~s(updated content</p>))
    end
  end

  describe "[article comment floor]" do
    test "comment will have a floor number after created", ~m(user blog)a do
      {:ok, blog_comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, blog_comment2} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, blog_comment} = ORM.find(ArticleComment, blog_comment.id)
      {:ok, blog_comment2} = ORM.find(ArticleComment, blog_comment2.id)

      assert blog_comment.floor == 1
      assert blog_comment2.floor == 2
    end
  end

  describe "[article comment participator for blog]" do
    test "blog will have participator after comment created", ~m(user blog)a do
      {:ok, _} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, blog} = ORM.find(Blog, blog.id)

      participator = List.first(blog.article_comments_participators)
      assert participator.id == user.id
    end

    test "psot participator will not contains same user", ~m(user blog)a do
      {:ok, _} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, blog} = ORM.find(Blog, blog.id)

      assert 1 == length(blog.article_comments_participators)
    end

    test "recent comment user should appear at first of the psot participators",
         ~m(user user2 blog)a do
      {:ok, _} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user2)

      {:ok, blog} = ORM.find(Blog, blog.id)

      participator = List.first(blog.article_comments_participators)

      assert participator.id == user2.id
    end
  end

  describe "[article comment upvotes]" do
    test "user can upvote a blog comment", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    test "article author upvote blog comment will have flag", ~m(blog user)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, author_user} = ORM.find(User, blog.author.user.id)

      CMS.upvote_article_comment(comment.id, author_user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)
      assert comment.meta.is_article_author_upvoted
    end

    test "user upvote blog comment will add id to upvoted_user_ids", ~m(blog user)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, comment} = CMS.upvote_article_comment(comment.id, user)

      assert user.id in comment.meta.upvoted_user_ids
    end

    test "user undo upvote blog comment will remove id from upvoted_user_ids",
         ~m(blog user user2)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _comment} = CMS.upvote_article_comment(comment.id, user)
      {:ok, comment} = CMS.upvote_article_comment(comment.id, user2)

      assert user2.id in comment.meta.upvoted_user_ids
      assert user.id in comment.meta.upvoted_user_ids

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user2)

      assert user.id in comment.meta.upvoted_user_ids
      assert user2.id not in comment.meta.upvoted_user_ids
    end

    test "user upvote a already-upvoted comment fails", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      CMS.upvote_article_comment(comment.id, user)
      {:error, _} = CMS.upvote_article_comment(comment.id, user)
    end

    test "upvote comment should inc the comment's upvotes_count", ~m(user user2 blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.upvotes_count == 0

      {:ok, _} = CMS.upvote_article_comment(comment.id, user)
      {:ok, _} = CMS.upvote_article_comment(comment.id, user2)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.upvotes_count == 2
    end

    test "user can undo upvote a blog comment", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    test "user can undo upvote a blog comment with no upvote", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end
  end

  describe "[article comment fold/unfold]" do
    test "user can fold a comment", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_folded

      {:ok, comment} = CMS.fold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_folded
    end

    test "user can unfold a comment", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _comment} = CMS.fold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_folded

      {:ok, _comment} = CMS.unfold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_folded
    end
  end

  describe "[article comment pin/unpin]" do
    test "user can pin a comment", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_pinned

      {:ok, comment} = CMS.pin_article_comment(comment.id)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_pinned

      {:ok, pined_record} = ArticlePinnedComment |> ORM.find_by(%{blog_id: blog.id})
      assert pined_record.blog_id == blog.id
    end

    test "user can unpin a comment", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, _comment} = CMS.pin_article_comment(comment.id)
      {:ok, comment} = CMS.undo_pin_article_comment(comment.id)

      assert not comment.is_pinned
      assert {:error, _} = ArticlePinnedComment |> ORM.find_by(%{article_comment_id: comment.id})
    end

    test "pinned comments has a limit for each article", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      Enum.reduce(0..(@pinned_comment_limit - 1), [], fn _, _acc ->
        {:ok, _comment} = CMS.pin_article_comment(comment.id)
      end)

      assert {:error, _} = CMS.pin_article_comment(comment.id)
    end
  end

  describe "[article comment report/unreport]" do
    #
    # test "user can report a comment", ~m(user blog)a do
    #   {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)

    #   {:ok, comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)
    # end

    #
    # test "user can unreport a comment", ~m(user blog)a do
    #   {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
    #   {:ok, _comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)

    #   {:ok, _comment} = CMS.undo_report_article_comment(comment.id, user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)
    # end

    test "can undo a report with other user report it too", ~m(user user2 blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, _comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user)
      {:ok, _comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user2)

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

    test "report user < @report_threshold_for_fold will not fold comment", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold - 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user)
      end)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_folded
    end

    test "report user > @report_threshold_for_fold will cause comment fold", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold + 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user)
      end)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_folded
    end
  end

  describe "paged article comments" do
    test "can load paged comments participators of a article", ~m(user blog)a do
      total_count = 30
      page_size = 10
      thread = :blog

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, new_user} = db_insert(:user)
        {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), new_user)

        acc ++ [comment]
      end)

      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, results} =
        CMS.paged_article_comments_participators(thread, blog.id, %{page: 1, size: page_size})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == total_count + 1
    end

    test "paged article comments folded flag should be false", ~m(user blog)a do
      total_count = 30
      page_number = 1
      page_size = 35

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

          acc ++ [comment]
        end)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :blog,
          blog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      random_comment = all_comments |> Enum.at(Enum.random(0..(total_count - 1)))

      assert not random_comment.is_folded

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end

    test "paged article comments should contains pinned comments at top position",
         ~m(user blog)a do
      total_count = 20
      page_number = 1
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_article_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_article_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :blog,
          blog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert pined_comment_1.id == List.first(paged_comments.entries) |> Map.get(:id)
      assert pined_comment_2.id == Enum.at(paged_comments.entries, 1) |> Map.get(:id)

      assert paged_comments.total_count == total_count + 2
    end

    test "only page 1 have pinned coments",
         ~m(user blog)a do
      total_count = 20
      page_number = 2
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_article_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_article_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :blog,
          blog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert not exist_in?(pined_comment_1, paged_comments.entries)
      assert not exist_in?(pined_comment_2, paged_comments.entries)

      assert paged_comments.total_count == total_count
    end

    test "paged article comments should not contains folded and repoted comments",
         ~m(user blog)a do
      total_count = 15
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment_1 = all_comments |> Enum.at(0)
      random_comment_2 = all_comments |> Enum.at(1)
      random_comment_3 = all_comments |> Enum.at(3)

      {:ok, _comment} = CMS.fold_article_comment(random_comment_1.id, user)
      {:ok, _comment} = CMS.fold_article_comment(random_comment_2.id, user)
      {:ok, _comment} = CMS.fold_article_comment(random_comment_3.id, user)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :blog,
          blog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert not exist_in?(random_comment_1, paged_comments.entries)
      assert not exist_in?(random_comment_2, paged_comments.entries)
      assert not exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count - 3 == paged_comments.total_count
    end

    test "can loaded paged folded comment", ~m(user blog)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_folded_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
          CMS.fold_article_comment(comment.id, user)

          acc ++ [comment]
        end)

      random_comment_1 = all_folded_comments |> Enum.at(1)
      random_comment_2 = all_folded_comments |> Enum.at(3)
      random_comment_3 = all_folded_comments |> Enum.at(5)

      {:ok, paged_comments} =
        CMS.paged_folded_article_comments(:blog, blog.id, %{page: page_number, size: page_size})

      assert exist_in?(random_comment_1, paged_comments.entries)
      assert exist_in?(random_comment_2, paged_comments.entries)
      assert exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end
  end

  describe "[article comment delete]" do
    test "delete comment still exsit in paged list and content is gone", ~m(user blog)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, deleted_comment} = CMS.delete_article_comment(random_comment)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :blog,
          blog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert exist_in?(deleted_comment, paged_comments.entries)
      assert deleted_comment.is_deleted
      assert deleted_comment.body_html == @delete_hint
    end

    test "delete comment still update article's comments_count field", ~m(user blog)a do
      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

      {:ok, blog} = ORM.find(Blog, blog.id)

      assert blog.article_comments_count == 5

      {:ok, _} = CMS.delete_article_comment(comment)

      {:ok, blog} = ORM.find(Blog, blog.id)
      assert blog.article_comments_count == 4
    end

    test "delete comment still delete pinned record if needed", ~m(user blog)a do
      total_count = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)

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
    test "author of the article comment a comment should have flag", ~m(user blog)a do
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      assert not comment.is_article_author

      author_user = blog.author.user
      {:ok, comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), author_user)
      assert comment.is_article_author
    end
  end

  describe "[lock/unlock blog comment]" do
    test "locked blog can not be comment", ~m(user blog)a do
      {:ok, _} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _} = CMS.lock_article_comment(:blog, blog.id)

      {:error, reason} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      assert reason |> is_error?(:article_comment_locked)

      {:ok, _} = CMS.undo_lock_article_comment(:blog, blog.id)
      {:ok, _} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
    end

    test "locked blog can not by reply", ~m(user blog)a do
      {:ok, parent_comment} = CMS.create_article_comment(:blog, blog.id, mock_comment(), user)
      {:ok, _} = CMS.reply_article_comment(parent_comment.id, mock_comment(), user)

      {:ok, _} = CMS.lock_article_comment(:blog, blog.id)

      {:error, reason} = CMS.reply_article_comment(parent_comment.id, mock_comment(), user)
      assert reason |> is_error?(:article_comment_locked)

      {:ok, _} = CMS.undo_lock_article_comment(:blog, blog.id)
      {:ok, _} = CMS.reply_article_comment(parent_comment.id, mock_comment(), user)
    end
  end
end
