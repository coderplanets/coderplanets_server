defmodule GroupherServer.Test.CMS.Comments.MeetupComment do
  @moduledoc false

  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias CMS.Model.{Comment, PinnedComment, Embeds, Meetup}

  @active_period get_config(:article, :active_period_days)

  @delete_hint Comment.delete_hint()
  @report_threshold_for_fold Comment.report_threshold_for_fold()
  @default_comment_meta Embeds.CommentMeta.default_meta()
  @pinned_comment_limit Comment.pinned_comment_limit()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, meetup} = db_insert(:meetup)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(community user user2 meetup)a}
  end

  describe "[basic article comment]" do
    test "meetup are supported by article comment.", ~m(user meetup)a do
      {:ok, meetup_comment_1} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, meetup_comment_2} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :comments)

      assert exist_in?(meetup_comment_1, meetup.comments)
      assert exist_in?(meetup_comment_2, meetup.comments)
    end

    test "comment should have default meta after create", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      assert comment.meta |> Map.from_struct() |> Map.delete(:id) == @default_comment_meta
    end

    test "create comment should update active timestamp of meetup", ~m(user meetup)a do
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :comments)

      assert not is_nil(meetup.active_at)
      assert meetup.active_at > meetup.inserted_at
    end

    test "meetup author create comment will not update active timestamp", ~m(community user)a do
      meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: [author: :user])

      Process.sleep(1000)

      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), meetup.author.user)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :comments)

      assert not is_nil(meetup.active_at)
      assert meetup.active_at == meetup.inserted_at
    end

    test "old meetup will not update active after comment created", ~m(user)a do
      active_period_days = Map.get(@active_period, :meetup)

      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days - 1)) |> Timex.to_datetime()

      {:ok, meetup} = db_insert(:meetup, %{inserted_at: inserted_at})
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, meetup} = ORM.find(Meetup, meetup.id)

      assert meetup.active_at |> DateTime.to_date() == DateTime.utc_now() |> DateTime.to_date()

      #####
      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days + 1)) |> Timex.to_datetime()

      {:ok, meetup} = db_insert(:meetup, %{inserted_at: inserted_at})
      Process.sleep(3000)
      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, meetup} = ORM.find(Meetup, meetup.id)

      assert meetup.active_at |> DateTime.to_unix() !== DateTime.utc_now() |> DateTime.to_unix()
    end

    test "comment can be updated", ~m(meetup user)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, updated_comment} = CMS.update_comment(comment, mock_comment("updated content"))

      assert updated_comment.body_html |> String.contains?(~s(updated content</p>))
    end
  end

  describe "[article comment floor]" do
    test "comment will have a floor number after created", ~m(user meetup)a do
      {:ok, meetup_comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, meetup_comment2} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, meetup_comment} = ORM.find(Comment, meetup_comment.id)
      {:ok, meetup_comment2} = ORM.find(Comment, meetup_comment2.id)

      assert meetup_comment.floor == 1
      assert meetup_comment2.floor == 2
    end
  end

  describe "[article comment participator for meetup]" do
    test "meetup will have participator after comment created", ~m(user meetup)a do
      {:ok, _} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, meetup} = ORM.find(Meetup, meetup.id)

      participator = List.first(meetup.comments_participants)
      assert participator.id == user.id
    end

    test "psot participator will not contains same user", ~m(user meetup)a do
      {:ok, _} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, meetup} = ORM.find(Meetup, meetup.id)

      assert 1 == length(meetup.comments_participants)
    end

    test "recent comment user should appear at first of the psot participants",
         ~m(user user2 meetup)a do
      {:ok, _} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user2)

      {:ok, meetup} = ORM.find(Meetup, meetup.id)

      participator = List.first(meetup.comments_participants)

      assert participator.id == user2.id
    end
  end

  describe "[article comment upvotes]" do
    test "user can upvote a meetup comment", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    test "article author upvote meetup comment will have flag", ~m(meetup user)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, author_user} = ORM.find(User, meetup.author.user.id)

      CMS.upvote_comment(comment.id, author_user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)
      assert comment.meta.is_article_author_upvoted
    end

    test "user upvote meetup comment will add id to upvoted_user_ids", ~m(meetup user)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, comment} = CMS.upvote_comment(comment.id, user)

      assert user.id in comment.meta.upvoted_user_ids
    end

    test "user undo upvote meetup comment will remove id from upvoted_user_ids",
         ~m(meetup user user2)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _comment} = CMS.upvote_comment(comment.id, user)
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)

      assert user2.id in comment.meta.upvoted_user_ids
      assert user.id in comment.meta.upvoted_user_ids

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user2)

      assert user.id in comment.meta.upvoted_user_ids
      assert user2.id not in comment.meta.upvoted_user_ids
    end

    test "user upvote a already-upvoted comment fails", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      CMS.upvote_comment(comment.id, user)
      {:error, _} = CMS.upvote_comment(comment.id, user)
    end

    test "upvote comment should inc the comment's upvotes_count", ~m(user user2 meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.upvotes_count == 0

      {:ok, _} = CMS.upvote_comment(comment.id, user)
      {:ok, _} = CMS.upvote_comment(comment.id, user2)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.upvotes_count == 2
    end

    test "user can undo upvote a meetup comment", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    test "user can undo upvote a meetup comment with no upvote", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end
  end

  describe "[article comment fold/unfold]" do
    test "user can fold a comment", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert not comment.is_folded

      {:ok, comment} = CMS.fold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.is_folded

      {:ok, meetup} = ORM.find(Meetup, meetup.id)
      assert meetup.meta.folded_comment_count == 1
    end

    test "user can unfold a comment", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _comment} = CMS.fold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert comment.is_folded

      {:ok, _comment} = CMS.unfold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert not comment.is_folded

      {:ok, meetup} = ORM.find(Meetup, meetup.id)
      assert meetup.meta.folded_comment_count == 0
    end
  end

  describe "[article comment pin/unpin]" do
    test "user can pin a comment", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert not comment.is_pinned

      {:ok, comment} = CMS.pin_comment(comment.id)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert comment.is_pinned

      {:ok, pined_record} = PinnedComment |> ORM.find_by(%{meetup_id: meetup.id})
      assert pined_record.meetup_id == meetup.id
    end

    test "user can unpin a comment", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, _comment} = CMS.pin_comment(comment.id)
      {:ok, comment} = CMS.undo_pin_comment(comment.id)

      assert not comment.is_pinned
      assert {:error, _} = PinnedComment |> ORM.find_by(%{comment_id: comment.id})
    end

    test "pinned comments has a limit for each article", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      Enum.reduce(0..(@pinned_comment_limit - 1), [], fn _, _acc ->
        {:ok, _comment} = CMS.pin_comment(comment.id)
      end)

      assert {:error, _} = CMS.pin_comment(comment.id)
    end
  end

  describe "[article comment report/unreport]" do
    #
    # test "user can report a comment", ~m(user meetup)a do
    #   {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)

    #   {:ok, comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)
    # end

    #
    # test "user can unreport a comment", ~m(user meetup)a do
    #   {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
    #   {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)

    #   {:ok, _comment} = CMS.undo_report_comment(comment.id, user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)
    # end

    test "can undo a report with other user report it too", ~m(user user2 meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user2)

      filter = %{content_type: :comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))

      {:ok, _report} = CMS.undo_report_article(:comment, comment.id, user)

      filter = %{content_type: :comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
    end

    test "report user < @report_threshold_for_fold will not fold comment", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold - 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      end)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert not comment.is_folded
    end

    test "report user > @report_threshold_for_fold will cause comment fold", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold + 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      end)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.is_folded
    end
  end

  describe "paged article comments" do
    test "can load paged comments participants of a article", ~m(user meetup)a do
      total_count = 30
      page_size = 10
      thread = :meetup

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, new_user} = db_insert(:user)
        {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), new_user)

        acc ++ [comment]
      end)

      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, results} =
        CMS.paged_comments_participants(thread, meetup.id, %{page: 1, size: page_size})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == total_count + 1
    end

    test "paged article comments folded flag should be false", ~m(user meetup)a do
      total_count = 30
      page_number = 1
      page_size = 35

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

          acc ++ [comment]
        end)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :meetup,
          meetup.id,
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
         ~m(user meetup)a do
      total_count = 20
      page_number = 1
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :meetup,
          meetup.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert pined_comment_1.id == List.first(paged_comments.entries) |> Map.get(:id)
      assert pined_comment_2.id == Enum.at(paged_comments.entries, 1) |> Map.get(:id)

      assert paged_comments.total_count == total_count + 2
    end

    test "only page 1 have pinned coments",
         ~m(user meetup)a do
      total_count = 20
      page_number = 2
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :meetup,
          meetup.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert not exist_in?(pined_comment_1, paged_comments.entries)
      assert not exist_in?(pined_comment_2, paged_comments.entries)

      assert paged_comments.total_count == total_count
    end

    test "paged article comments should not contains folded and repoted comments",
         ~m(user meetup)a do
      total_count = 15
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment_1 = all_comments |> Enum.at(0)
      random_comment_2 = all_comments |> Enum.at(1)
      random_comment_3 = all_comments |> Enum.at(3)

      {:ok, _comment} = CMS.fold_comment(random_comment_1.id, user)
      {:ok, _comment} = CMS.fold_comment(random_comment_2.id, user)
      {:ok, _comment} = CMS.fold_comment(random_comment_3.id, user)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :meetup,
          meetup.id,
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

    test "can loaded paged folded comment", ~m(user meetup)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_folded_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
          CMS.fold_comment(comment.id, user)

          acc ++ [comment]
        end)

      random_comment_1 = all_folded_comments |> Enum.at(1)
      random_comment_2 = all_folded_comments |> Enum.at(3)
      random_comment_3 = all_folded_comments |> Enum.at(5)

      {:ok, paged_comments} =
        CMS.paged_folded_comments(:meetup, meetup.id, %{page: page_number, size: page_size})

      assert exist_in?(random_comment_1, paged_comments.entries)
      assert exist_in?(random_comment_2, paged_comments.entries)
      assert exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end
  end

  describe "[article comment delete]" do
    test "delete comment still exsit in paged list and content is gone", ~m(user meetup)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, deleted_comment} = CMS.delete_comment(random_comment)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :meetup,
          meetup.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert exist_in?(deleted_comment, paged_comments.entries)
      assert deleted_comment.is_deleted
      assert deleted_comment.body_html == @delete_hint
    end

    test "delete comment still update article's comments_count field", ~m(user meetup)a do
      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

      {:ok, meetup} = ORM.find(Meetup, meetup.id)

      assert meetup.comments_count == 5

      {:ok, _} = CMS.delete_comment(comment)

      {:ok, meetup} = ORM.find(Meetup, meetup.id)
      assert meetup.comments_count == 4
    end

    test "delete comment still delete pinned record if needed", ~m(user meetup)a do
      total_count = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, _comment} = CMS.pin_comment(random_comment.id)
      {:ok, _comment} = ORM.find(Comment, random_comment.id)

      {:ok, _} = CMS.delete_comment(random_comment)
      assert {:error, _comment} = ORM.find(PinnedComment, random_comment.id)
    end
  end

  describe "[article comment info]" do
    test "author of the article comment a comment should have flag", ~m(user meetup)a do
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      assert not comment.is_article_author

      author_user = meetup.author.user
      {:ok, comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), author_user)
      assert comment.is_article_author
    end
  end

  describe "[lock/unlock meetup comment]" do
    test "locked meetup can not be comment", ~m(user meetup)a do
      {:ok, _} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _} = CMS.lock_article_comments(:meetup, meetup.id)

      {:error, reason} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      assert reason |> is_error?(:article_comments_locked)

      {:ok, _} = CMS.undo_lock_article_comments(:meetup, meetup.id)
      {:ok, _} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
    end

    test "locked meetup can not by reply", ~m(user meetup)a do
      {:ok, parent_comment} = CMS.create_comment(:meetup, meetup.id, mock_comment(), user)
      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user)

      {:ok, _} = CMS.lock_article_comments(:meetup, meetup.id)

      {:error, reason} = CMS.reply_comment(parent_comment.id, mock_comment(), user)
      assert reason |> is_error?(:article_comments_locked)

      {:ok, _} = CMS.undo_lock_article_comments(:meetup, meetup.id)
      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user)
    end
  end
end