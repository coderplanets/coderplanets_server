defmodule GroupherServer.Test.CMS.Comments.PostComment do
  @moduledoc false

  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}
  alias Accounts.Model.User
  alias CMS.Model.{Comment, PinnedComment, Embeds, Post}

  @active_period get_config(:article, :active_period_days)

  @delete_hint Comment.delete_hint()
  @report_threshold_for_fold Comment.report_threshold_for_fold()
  @default_comment_meta Embeds.CommentMeta.default_meta()
  @pinned_comment_limit Comment.pinned_comment_limit()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(community user user2 user3 post)a}
  end

  describe "[comments state]" do
    test "can get basic state", ~m(user post)a do
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, state} = CMS.comments_state(:post, post.id)

      assert state.participants_count == 1
      assert state.total_count == 2

      assert state.participants |> length == 1
      assert not state.is_viewer_joined
    end

    test "can get viewer joined state", ~m(user post)a do
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, state} = CMS.comments_state(:post, post.id, user)

      assert state.participants_count == 1
      assert state.total_count == 2
      assert state.participants |> length == 1
      assert state.is_viewer_joined
    end

    test "can get viewer joined state 2", ~m(user user2 user3 post)a do
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user2)
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user3)

      {:ok, state} = CMS.comments_state(:post, post.id, user)

      assert state.participants_count == 2
      assert state.total_count == 2
      assert state.participants |> length == 2
      assert not state.is_viewer_joined
    end
  end

  describe "[basic article comment]" do
    test "post are supported by article comment.", ~m(user post)a do
      {:ok, post_comment_1} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, post_comment_2} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, post} = ORM.find(Post, post.id, preload: :comments)

      assert exist_in?(post_comment_1, post.comments)
      assert exist_in?(post_comment_2, post.comments)
    end

    test "comment should have default meta after create", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      assert comment.meta |> Map.from_struct() |> Map.delete(:id) == @default_comment_meta
    end

    test "create comment should update active timestamp of post", ~m(user post)a do
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, post} = ORM.find(Post, post.id, preload: :comments)

      assert not is_nil(post.active_at)
      assert post.active_at > post.inserted_at
    end

    test "post author create comment will not update active timestamp", ~m(community user)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])

      Process.sleep(1000)

      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), post.author.user)

      {:ok, post} = ORM.find(Post, post.id, preload: :comments)

      assert not is_nil(post.active_at)
      assert post.active_at == post.inserted_at
    end

    test "old post will not update active after comment created", ~m(user)a do
      active_period_days = @active_period[:post] || @active_period[:default]

      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days - 1)) |> Timex.to_datetime()

      {:ok, post} = db_insert(:post, %{inserted_at: inserted_at})
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, post} = ORM.find(Post, post.id)

      assert post.active_at |> DateTime.to_date() == DateTime.utc_now() |> DateTime.to_date()

      #####
      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days + 1)) |> Timex.to_datetime()

      {:ok, post} = db_insert(:post, %{inserted_at: inserted_at})
      Process.sleep(3000)
      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, post} = ORM.find(Post, post.id)

      assert post.active_at |> DateTime.to_unix() !== DateTime.utc_now() |> DateTime.to_unix()
    end

    test "comment can be updated", ~m(post user)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, updated_comment} = CMS.update_comment(comment, mock_comment("updated content"))

      assert updated_comment.body_html |> String.contains?(~s(updated content</p>))
    end
  end

  describe "[article comment floor]" do
    test "comment will have a floor number after created", ~m(user post)a do
      {:ok, post_comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, post_comment2} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, post_comment} = ORM.find(Comment, post_comment.id)
      {:ok, post_comment2} = ORM.find(Comment, post_comment2.id)

      assert post_comment.floor == 1
      assert post_comment2.floor == 2
    end
  end

  describe "[article comment participator for post]" do
    test "post will have participator after comment created", ~m(user post)a do
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, post} = ORM.find(Post, post.id)

      participator = List.first(post.comments_participants)
      assert participator.id == user.id
    end

    test "psot participator will not contains same user", ~m(user post)a do
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, post} = ORM.find(Post, post.id)

      assert 1 == length(post.comments_participants)
    end

    test "recent comment user should appear at first of the psot participants",
         ~m(user user2 post)a do
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user2)

      {:ok, post} = ORM.find(Post, post.id)

      participator = List.first(post.comments_participants)

      assert participator.id == user2.id
    end
  end

  describe "[article comment upvotes]" do
    test "user can upvote a post comment", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    test "user can upvote a post comment twice is fine", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, _} = CMS.upvote_comment(comment.id, user)
      {:error, _} = CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)
    end

    test "article author upvote post comment will have flag", ~m(post user)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, author_user} = ORM.find(User, post.author.user.id)

      CMS.upvote_comment(comment.id, author_user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)
      assert comment.meta.is_article_author_upvoted
    end

    test "user upvote post comment will add id to upvoted_user_ids", ~m(post user)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment} = CMS.upvote_comment(comment.id, user)

      assert user.id in comment.meta.upvoted_user_ids
    end

    test "user undo upvote post comment will remove id from upvoted_user_ids",
         ~m(post user user2)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _comment} = CMS.upvote_comment(comment.id, user)
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)

      assert user2.id in comment.meta.upvoted_user_ids
      assert user.id in comment.meta.upvoted_user_ids

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user2)

      assert user.id in comment.meta.upvoted_user_ids
      assert user2.id not in comment.meta.upvoted_user_ids
    end

    test "user upvote a already-upvoted comment fails", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      CMS.upvote_comment(comment.id, user)
      {:error, _} = CMS.upvote_comment(comment.id, user)
    end

    test "upvote comment should inc the comment's upvotes_count", ~m(user user2 post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.upvotes_count == 0

      {:ok, _} = CMS.upvote_comment(comment.id, user)
      {:ok, _} = CMS.upvote_comment(comment.id, user2)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.upvotes_count == 2
    end

    test "user can undo upvote a post comment", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    test "user can undo upvote a post comment with no upvote", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    test "upvote comment should update embeded replies too", ~m(user user2 user3 post)a do
      {:ok, parent_comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, replied_comment} = CMS.reply_comment(parent_comment.id, mock_comment(), user)

      {:ok, _} = CMS.upvote_comment(parent_comment.id, user)
      {:ok, _} = CMS.upvote_comment(replied_comment.id, user)
      {:ok, _} = CMS.upvote_comment(replied_comment.id, user2)
      {:ok, _} = CMS.upvote_comment(replied_comment.id, user3)

      filter = %{page: 1, size: 20}
      {:ok, paged_comments} = CMS.paged_comments(:post, post.id, filter, :replies)

      parent = paged_comments.entries |> List.first()
      reply = parent |> Map.get(:replies) |> List.first()
      assert parent.upvotes_count == 1
      assert reply.upvotes_count == 3

      {:ok, _} = CMS.undo_upvote_comment(replied_comment.id, user2)
      {:ok, paged_comments} = CMS.paged_comments(:post, post.id, filter, :replies)

      parent = paged_comments.entries |> List.first()
      reply = parent |> Map.get(:replies) |> List.first()
      assert parent.upvotes_count == 1
      assert reply.upvotes_count == 2
    end
  end

  describe "[article comment fold/unfold]" do
    test "user can fold a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert not comment.is_folded

      {:ok, comment} = CMS.fold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.is_folded

      {:ok, post} = ORM.find(Post, post.id)
      assert post.meta.folded_comment_count == 1
    end

    test "user can unfold a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _comment} = CMS.fold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert comment.is_folded

      {:ok, _comment} = CMS.unfold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert not comment.is_folded

      {:ok, post} = ORM.find(Post, post.id)
      assert post.meta.folded_comment_count == 0
    end
  end

  describe "[article comment pin/unpin]" do
    test "user can pin a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert not comment.is_pinned

      {:ok, comment} = CMS.pin_comment(comment.id)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert comment.is_pinned

      {:ok, pined_record} = PinnedComment |> ORM.find_by(%{post_id: post.id})
      assert pined_record.post_id == post.id
    end

    test "user can unpin a comment", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, _comment} = CMS.pin_comment(comment.id)
      {:ok, comment} = CMS.undo_pin_comment(comment.id)

      assert not comment.is_pinned
      assert {:error, _} = PinnedComment |> ORM.find_by(%{comment_id: comment.id})
    end

    test "pinned comments has a limit for each article", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      Enum.reduce(0..(@pinned_comment_limit - 1), [], fn _, _acc ->
        {:ok, _comment} = CMS.pin_comment(comment.id)
      end)

      assert {:error, _} = CMS.pin_comment(comment.id)
    end
  end

  describe "[article comment report/unreport]" do
    #
    # test "user can report a comment", ~m(user post)a do
    #   {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)

    #   {:ok, comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)
    # end

    #
    # test "user can unreport a comment", ~m(user post)a do
    #   {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
    #   {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)

    #   {:ok, _comment} = CMS.undo_report_comment(comment.id, user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)
    # end

    test "can undo a report with other user report it too", ~m(user user2 post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

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

    test "report user < @report_threshold_for_fold will not fold comment", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold - 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      end)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert not comment.is_folded
    end

    test "report user > @report_threshold_for_fold will cause comment fold", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

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
    test "can load paged comments participants of a article", ~m(user post)a do
      total_count = 30
      page_size = 10
      thread = :post

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, new_user} = db_insert(:user)
        {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), new_user)

        acc ++ [comment]
      end)

      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, results} =
        CMS.paged_comments_participants(thread, post.id, %{page: 1, size: page_size})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == total_count + 1
    end

    test "paged article comments folded flag should be false", ~m(user post)a do
      total_count = 30
      page_number = 1
      page_size = 35

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

          acc ++ [comment]
        end)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :post,
          post.id,
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
         ~m(user post)a do
      total_count = 20
      page_number = 1
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :post,
          post.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert pined_comment_1.id == List.first(paged_comments.entries) |> Map.get(:id)
      assert pined_comment_2.id == Enum.at(paged_comments.entries, 1) |> Map.get(:id)

      assert paged_comments.total_count == total_count + 2
    end

    test "only page 1 have pinned coments",
         ~m(user post)a do
      total_count = 20
      page_number = 2
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :post,
          post.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert not exist_in?(pined_comment_1, paged_comments.entries)
      assert not exist_in?(pined_comment_2, paged_comments.entries)

      assert paged_comments.total_count == total_count
    end

    test "paged article comments should not contains folded and repoted comments",
         ~m(user post)a do
      total_count = 15
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

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
          :post,
          post.id,
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

    test "can loaded paged folded comment", ~m(user post)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_folded_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
          CMS.fold_comment(comment.id, user)

          acc ++ [comment]
        end)

      random_comment_1 = all_folded_comments |> Enum.at(1)
      random_comment_2 = all_folded_comments |> Enum.at(3)
      random_comment_3 = all_folded_comments |> Enum.at(5)

      {:ok, paged_comments} =
        CMS.paged_folded_comments(:post, post.id, %{page: page_number, size: page_size})

      assert exist_in?(random_comment_1, paged_comments.entries)
      assert exist_in?(random_comment_2, paged_comments.entries)
      assert exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end
  end

  describe "[article comment delete]" do
    test "delete comment still exsit in paged list and content is gone", ~m(user post)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, deleted_comment} = CMS.delete_comment(random_comment)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :post,
          post.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert exist_in?(deleted_comment, paged_comments.entries)
      assert deleted_comment.is_deleted
      assert deleted_comment.body_html == @delete_hint
    end

    test "delete comment still update article's comments_count field", ~m(user post)a do
      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      {:ok, post} = ORM.find(Post, post.id)

      assert post.comments_count == 5

      {:ok, _} = CMS.delete_comment(comment)

      {:ok, post} = ORM.find(Post, post.id)
      assert post.comments_count == 4
    end

    test "delete comment still delete pinned record if needed", ~m(user post)a do
      total_count = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

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
    test "author of the article comment a comment should have flag", ~m(user post)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      assert not comment.is_article_author

      author_user = post.author.user
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), author_user)
      assert comment.is_article_author
    end
  end

  describe "[lock/unlock post comment]" do
    test "locked post can not be comment", ~m(user post)a do
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.lock_article_comments(:post, post.id)

      {:error, reason} = CMS.create_comment(:post, post.id, mock_comment(), user)
      assert reason |> is_error?(:article_comments_locked)

      {:ok, _} = CMS.undo_lock_article_comments(:post, post.id)
      {:ok, _} = CMS.create_comment(:post, post.id, mock_comment(), user)
    end

    test "locked post can not by reply", ~m(user post)a do
      {:ok, parent_comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user)

      {:ok, _} = CMS.lock_article_comments(:post, post.id)

      {:error, reason} = CMS.reply_comment(parent_comment.id, mock_comment(), user)
      assert reason |> is_error?(:article_comments_locked)

      {:ok, _} = CMS.undo_lock_article_comments(:post, post.id)
      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user)
    end
  end

  describe "[article comment qa type]" do
    test "create comment for normal post should have default qa flags", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post_comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      assert not post_comment.is_for_question
      assert not post_comment.is_solution
    end

    test "create comment for question post should have flags", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, post_comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      assert post_comment.is_for_question
    end

    test "update comment with is_question should batch update exsit comments is_for_question field",
         ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, comment1} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment2} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, comment3} = CMS.create_comment(:post, post.id, mock_comment(), user)

      assert comment1.is_for_question
      assert comment2.is_for_question
      assert comment3.is_for_question

      {:ok, _} = CMS.update_article(post, %{is_question: false})

      {:ok, comment1} = ORM.find(Comment, comment1.id)
      {:ok, comment2} = ORM.find(Comment, comment2.id)
      {:ok, comment3} = ORM.find(Comment, comment3.id)

      assert not comment1.is_for_question
      assert not comment2.is_for_question
      assert not comment3.is_for_question
    end

    test "can mark a comment as solution", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user

      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), post_author)
      {:ok, comment} = CMS.mark_comment_solution(comment.id, post_author)

      assert comment.is_solution

      {:ok, post} = ORM.find(Post, post.id)
      assert post.is_solved
      assert post.solution_digest == comment.body_html
    end

    test "non-post-author can not mark a comment as solution", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user
      {:ok, random_user} = db_insert(:user)

      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), post_author)
      {:error, reason} = CMS.mark_comment_solution(comment.id, random_user)

      reason |> is_error?(:require_questioner)
    end

    test "can undo mark a comment as solution", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user

      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), post_author)
      {:ok, comment} = CMS.mark_comment_solution(comment.id, post_author)

      {:ok, comment} = CMS.undo_mark_comment_solution(comment.id, post_author)

      assert not comment.is_solution

      {:ok, post} = ORM.find(Post, post.id)
      assert not post.is_solved
    end

    test "non-post-author can not undo mark a comment as solution", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user
      {:ok, random_user} = db_insert(:user)

      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), post_author)
      {:error, reason} = CMS.undo_mark_comment_solution(comment.id, random_user)

      reason |> is_error?(:require_questioner)
    end

    test "can only mark one best comment as solution", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user

      {:ok, comment1} = CMS.create_comment(:post, post.id, mock_comment(), post_author)
      {:ok, comment2} = CMS.create_comment(:post, post.id, mock_comment(), post_author)

      {:ok, _comment} = CMS.mark_comment_solution(comment1.id, post_author)
      {:ok, comment2} = CMS.mark_comment_solution(comment2.id, post_author)

      answers =
        from(c in Comment, where: c.post_id == ^post.id and c.is_solution == true)
        |> Repo.all()

      assert answers |> length == 1
      assert answers |> List.first() |> Map.get(:id) == comment2.id
    end

    test "update a solution should also update post's solution digest", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user

      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment("solution"), post_author)

      {:ok, comment} = CMS.mark_comment_solution(comment.id, post_author)

      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      assert post.solution_digest |> String.contains?(~s(<p id=))
      assert post.solution_digest |> String.contains?(~s(solution</p>))

      {:ok, _comment} = CMS.update_comment(comment, mock_comment("new solution"))
      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      assert post.solution_digest == "new solution"
    end
  end

  describe "[update user info in comments_participants]" do
    test "basic find", ~m(user community)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id, is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, _comment} = CMS.create_comment(:post, post.id, mock_comment("solution"), user)

      CMS.update_user_in_comments_participants(user)
    end
  end
end
