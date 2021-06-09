defmodule GroupherServer.Test.CMS.Comments.RepoComment do
  @moduledoc false

  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias CMS.Model.{ArticleComment, ArticlePinnedComment, Embeds, Repo}

  @active_period get_config(:article, :active_period_days)

  @delete_hint ArticleComment.delete_hint()
  @report_threshold_for_fold ArticleComment.report_threshold_for_fold()
  @default_comment_meta Embeds.ArticleCommentMeta.default_meta()
  @pinned_comment_limit ArticleComment.pinned_comment_limit()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, repo} = db_insert(:repo)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(community user user2 repo)a}
  end

  describe "[basic article comment]" do
    test "repo are supported by article comment.", ~m(user repo)a do
      {:ok, repo_comment_1} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, repo_comment_2} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :article_comments)

      assert exist_in?(repo_comment_1, repo.article_comments)
      assert exist_in?(repo_comment_2, repo.article_comments)
    end

    test "comment should have default meta after create", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      assert comment.meta |> Map.from_struct() |> Map.delete(:id) == @default_comment_meta
    end

    test "create comment should update active timestamp of repo", ~m(user repo)a do
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, repo} = ORM.find(Repo, repo.id, preload: :article_comments)

      assert not is_nil(repo.active_at)
      assert repo.active_at > repo.inserted_at
    end

    test "repo author create comment will not update active timestamp", ~m(community user)a do
      repo_attrs = mock_attrs(:repo, %{community_id: community.id})
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, repo} = ORM.find(Repo, repo.id, preload: [author: :user])

      Process.sleep(1000)

      {:ok, _comment} =
        CMS.create_article_comment(:repo, repo.id, "repo comment", repo.author.user)

      {:ok, repo} = ORM.find(Repo, repo.id, preload: :article_comments)

      assert not is_nil(repo.active_at)
      assert repo.active_at == repo.inserted_at
    end

    test "old repo will not update active after comment created", ~m(user)a do
      active_period_days = Map.get(@active_period, :repo)

      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days - 1)) |> Timex.to_datetime()

      {:ok, repo} = db_insert(:repo, %{inserted_at: inserted_at})
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, repo} = ORM.find(Repo, repo.id)

      assert repo.active_at |> DateTime.to_date() == DateTime.utc_now() |> DateTime.to_date()

      #####
      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days + 1)) |> Timex.to_datetime()

      {:ok, repo} = db_insert(:repo, %{inserted_at: inserted_at})
      Process.sleep(3000)
      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, repo} = ORM.find(Repo, repo.id)

      assert repo.active_at |> DateTime.to_unix() !== DateTime.utc_now() |> DateTime.to_unix()
    end

    test "comment can be updated", ~m(repo user)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, updated_comment} = CMS.update_article_comment(comment, "updated content")

      assert updated_comment.body_html == "updated content"
    end
  end

  describe "[article comment floor]" do
    test "comment will have a floor number after created", ~m(user repo)a do
      {:ok, repo_comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, repo_comment2} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, repo_comment} = ORM.find(ArticleComment, repo_comment.id)
      {:ok, repo_comment2} = ORM.find(ArticleComment, repo_comment2.id)

      assert repo_comment.floor == 1
      assert repo_comment2.floor == 2
    end
  end

  describe "[article comment participator for repo]" do
    test "repo will have participator after comment created", ~m(user repo)a do
      {:ok, _} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, repo} = ORM.find(Repo, repo.id)

      participator = List.first(repo.article_comments_participators)
      assert participator.id == user.id
    end

    test "psot participator will not contains same user", ~m(user repo)a do
      {:ok, _} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, repo} = ORM.find(Repo, repo.id)

      assert 1 == length(repo.article_comments_participators)
    end

    test "recent comment user should appear at first of the psot participators",
         ~m(user user2 repo)a do
      {:ok, _} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user2)

      {:ok, repo} = ORM.find(Repo, repo.id)

      participator = List.first(repo.article_comments_participators)

      assert participator.id == user2.id
    end
  end

  describe "[article comment upvotes]" do
    test "user can upvote a repo comment", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    test "article author upvote repo comment will have flag", ~m(repo user)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, author_user} = ORM.find(User, repo.author.user.id)

      CMS.upvote_article_comment(comment.id, author_user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)
      assert comment.meta.is_article_author_upvoted
    end

    test "user upvote repo comment will add id to upvoted_user_ids", ~m(repo user)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, comment} = CMS.upvote_article_comment(comment.id, user)

      assert user.id in comment.meta.upvoted_user_ids
    end

    test "user undo upvote repo comment will remove id from upvoted_user_ids",
         ~m(repo user user2)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _comment} = CMS.upvote_article_comment(comment.id, user)
      {:ok, comment} = CMS.upvote_article_comment(comment.id, user2)

      assert user2.id in comment.meta.upvoted_user_ids
      assert user.id in comment.meta.upvoted_user_ids

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user2)

      assert user.id in comment.meta.upvoted_user_ids
      assert user2.id not in comment.meta.upvoted_user_ids
    end

    test "user upvote a already-upvoted comment fails", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      CMS.upvote_article_comment(comment.id, user)
      {:error, _} = CMS.upvote_article_comment(comment.id, user)
    end

    test "upvote comment should inc the comment's upvotes_count", ~m(user user2 repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.upvotes_count == 0

      {:ok, _} = CMS.upvote_article_comment(comment.id, user)
      {:ok, _} = CMS.upvote_article_comment(comment.id, user2)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.upvotes_count == 2
    end

    test "user can undo upvote a repo comment", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      CMS.upvote_article_comment(comment.id, user)

      {:ok, comment} = ORM.find(ArticleComment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    test "user can undo upvote a repo comment with no upvote", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count

      {:ok, comment} = CMS.undo_upvote_article_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end
  end

  describe "[article comment fold/unfold]" do
    test "user can fold a comment", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_folded

      {:ok, comment} = CMS.fold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert comment.is_folded
    end

    test "user can unfold a comment", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _comment} = CMS.fold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_folded

      {:ok, _comment} = CMS.unfold_article_comment(comment.id, user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_folded
    end
  end

  describe "[article comment pin/unpin]" do
    test "user can pin a comment", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert not comment.is_pinned

      {:ok, comment} = CMS.pin_article_comment(comment.id)
      {:ok, comment} = ORM.find(ArticleComment, comment.id)

      assert comment.is_pinned

      {:ok, pined_record} = ArticlePinnedComment |> ORM.find_by(%{repo_id: repo.id})
      assert pined_record.repo_id == repo.id
    end

    test "user can unpin a comment", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, _comment} = CMS.pin_article_comment(comment.id)
      {:ok, comment} = CMS.undo_pin_article_comment(comment.id)

      assert not comment.is_pinned
      assert {:error, _} = ArticlePinnedComment |> ORM.find_by(%{article_comment_id: comment.id})
    end

    test "pinned comments has a limit for each article", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      Enum.reduce(0..(@pinned_comment_limit - 1), [], fn _, _acc ->
        {:ok, _comment} = CMS.pin_article_comment(comment.id)
      end)

      assert {:error, _} = CMS.pin_article_comment(comment.id)
    end
  end

  describe "[article comment report/unreport]" do
    #
    # test "user can report a comment", ~m(user repo)a do
    #   {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)

    #   {:ok, comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)
    # end

    #
    # test "user can unreport a comment", ~m(user repo)a do
    #   {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
    #   {:ok, _comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)

    #   {:ok, _comment} = CMS.undo_report_article_comment(comment.id, user)
    #   {:ok, comment} = ORM.find(ArticleComment, comment.id)
    # end

    test "can undo a report with other user report it too", ~m(user user2 repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

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

    test "report user < @report_threshold_for_fold will not fold comment", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold - 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_article_comment(comment.id, mock_comment(), "attr", user)
      end)

      {:ok, comment} = ORM.find(ArticleComment, comment.id)
      assert not comment.is_folded
    end

    test "report user > @report_threshold_for_fold will cause comment fold", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

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
    test "can load paged comments participators of a article", ~m(user repo)a do
      total_count = 30
      page_size = 10
      thread = :repo

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, new_user} = db_insert(:user)
        {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), new_user)

        acc ++ [comment]
      end)

      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, results} =
        CMS.paged_article_comments_participators(thread, repo.id, %{page: 1, size: page_size})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == total_count + 1
    end

    test "paged article comments folded flag should be false", ~m(user repo)a do
      total_count = 30
      page_number = 1
      page_size = 35

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

          acc ++ [comment]
        end)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :repo,
          repo.id,
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
         ~m(user repo)a do
      total_count = 20
      page_number = 1
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_article_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_article_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :repo,
          repo.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert pined_comment_1.id == List.first(paged_comments.entries) |> Map.get(:id)
      assert pined_comment_2.id == Enum.at(paged_comments.entries, 1) |> Map.get(:id)

      assert paged_comments.total_count == total_count + 2
    end

    test "only page 1 have pinned coments",
         ~m(user repo)a do
      total_count = 20
      page_number = 2
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_article_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_article_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :repo,
          repo.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert not exist_in?(pined_comment_1, paged_comments.entries)
      assert not exist_in?(pined_comment_2, paged_comments.entries)

      assert paged_comments.total_count == total_count
    end

    test "paged article comments should not contains folded and repoted comments",
         ~m(user repo)a do
      total_count = 15
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

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
          :repo,
          repo.id,
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

    test "can loaded paged folded comment", ~m(user repo)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_folded_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
          CMS.fold_article_comment(comment.id, user)

          acc ++ [comment]
        end)

      random_comment_1 = all_folded_comments |> Enum.at(1)
      random_comment_2 = all_folded_comments |> Enum.at(3)
      random_comment_3 = all_folded_comments |> Enum.at(5)

      {:ok, paged_comments} =
        CMS.paged_folded_article_comments(:repo, repo.id, %{page: page_number, size: page_size})

      assert exist_in?(random_comment_1, paged_comments.entries)
      assert exist_in?(random_comment_2, paged_comments.entries)
      assert exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end
  end

  describe "[article comment delete]" do
    test "delete comment still exsit in paged list and content is gone", ~m(user repo)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, deleted_comment} = CMS.delete_article_comment(random_comment)

      {:ok, paged_comments} =
        CMS.paged_article_comments(
          :repo,
          repo.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert exist_in?(deleted_comment, paged_comments.entries)
      assert deleted_comment.is_deleted
      assert deleted_comment.body_html == @delete_hint
    end

    test "delete comment still update article's comments_count field", ~m(user repo)a do
      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

      {:ok, repo} = ORM.find(Repo, repo.id)

      assert repo.article_comments_count == 5

      {:ok, _} = CMS.delete_article_comment(comment)

      {:ok, repo} = ORM.find(Repo, repo.id)
      assert repo.article_comments_count == 4
    end

    test "delete comment still delete pinned record if needed", ~m(user repo)a do
      total_count = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)

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
    test "author of the article comment a comment should have flag", ~m(user repo)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      assert not comment.is_article_author

      author_user = repo.author.user
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), author_user)
      assert comment.is_article_author
    end
  end

  describe "[lock/unlock repo comment]" do
    test "locked repo can not be comment", ~m(user repo)a do
      {:ok, _} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _} = CMS.lock_article_comment(:repo, repo.id)

      {:error, reason} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      assert reason |> is_error?(:article_comment_locked)

      {:ok, _} = CMS.undo_lock_article_comment(:repo, repo.id)
      {:ok, _} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
    end

    test "locked repo can not by reply", ~m(user repo)a do
      {:ok, parent_comment} = CMS.create_article_comment(:repo, repo.id, mock_comment(), user)
      {:ok, _} = CMS.reply_article_comment(parent_comment.id, mock_comment(), user)

      {:ok, _} = CMS.lock_article_comment(:repo, repo.id)

      {:error, reason} = CMS.reply_article_comment(parent_comment.id, mock_comment(), user)
      assert reason |> is_error?(:article_comment_locked)

      {:ok, _} = CMS.undo_lock_article_comment(:repo, repo.id)
      {:ok, _} = CMS.reply_article_comment(parent_comment.id, mock_comment(), user)
    end
  end
end
