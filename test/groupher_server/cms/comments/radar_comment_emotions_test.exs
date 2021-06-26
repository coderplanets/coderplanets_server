defmodule GroupherServer.Test.CMS.Comments.RadarCommentEmotions do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Comment, Embeds, CommentUserEmotion}

  @default_emotions Embeds.CommentEmotion.default_emotions()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    {:ok, radar} = db_insert(:radar)

    {:ok, ~m(user user2 user3 radar)a}
  end

  describe "[emotion in paged article comment]" do
    test "login user should got viewer has emotioned status", ~m(radar user)a do
      total_count = 0
      page_number = 10
      page_size = 20

      all_comment =
        Enum.reduce(0..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)
          acc ++ [comment]
        end)

      first_comment = List.first(all_comment)

      {:ok, _} = CMS.emotion_to_comment(first_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(first_comment.id, :beer, user)
      {:ok, _} = CMS.emotion_to_comment(first_comment.id, :popcorn, user)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :radar,
          radar.id,
          %{page: page_number, size: page_size},
          :replies,
          user
        )

      target = Enum.find(paged_comments.entries, &(&1.id == first_comment.id))

      assert target.emotions.downvote_count == 1
      assert user_exist_in?(user, target.emotions.latest_downvote_users)
      assert target.emotions.viewer_has_downvoteed

      assert target.emotions.beer_count == 1
      assert user_exist_in?(user, target.emotions.latest_beer_users)
      assert target.emotions.viewer_has_beered

      assert target.emotions.popcorn_count == 1
      assert user_exist_in?(user, target.emotions.latest_popcorn_users)
      assert target.emotions.viewer_has_popcorned
    end
  end

  describe "[basic article comment emotion]" do
    test "comment has default emotions after created", ~m(radar user)a do
      {:ok, parent_comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)
      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)

      emotions = parent_comment.emotions |> Map.from_struct() |> Map.delete(:id)
      assert @default_emotions == emotions
    end

    test "can make emotion to comment", ~m(radar user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Comment, parent_comment.id)

      assert emotions.downvote_count == 2
      assert user_exist_in?(user, emotions.latest_downvote_users)
      assert user_exist_in?(user2, emotions.latest_downvote_users)
    end

    test "can undo emotion to comment", ~m(radar user user2)a do
      {:ok, parent_comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Comment, parent_comment.id)

      assert emotions.downvote_count == 2
      assert user_exist_in?(user, emotions.latest_downvote_users)
      assert user_exist_in?(user2, emotions.latest_downvote_users)

      {:ok, _} = CMS.undo_emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.undo_emotion_to_comment(parent_comment.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Comment, parent_comment.id)
      assert emotions.downvote_count == 0
      assert not user_exist_in?(user, emotions.latest_downvote_users)
      assert not user_exist_in?(user2, emotions.latest_downvote_users)
    end

    test "same user make same emotion to same comment.", ~m(radar user)a do
      {:ok, parent_comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)

      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)

      assert parent_comment.emotions.downvote_count == 1
      assert user_exist_in?(user, parent_comment.emotions.latest_downvote_users)
    end

    test "same user same emotion to same comment only have one user_emotion record",
         ~m(radar user)a do
      {:ok, parent_comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :heart, user)

      {:ok, parent_comment} = ORM.find(Comment, parent_comment.id)

      {:ok, records} = ORM.find_all(CommentUserEmotion, %{page: 1, size: 10})
      assert records.total_count == 1

      {:ok, record} =
        ORM.find_by(CommentUserEmotion, %{
          comment_id: parent_comment.id,
          user_id: user.id
        })

      assert record.downvote
      assert record.heart
    end

    test "different user can make same emotions on same comment", ~m(radar user user2 user3)a do
      {:ok, parent_comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :beer, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :beer, user2)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :beer, user3)

      {:ok, %{emotions: emotions}} = ORM.find(Comment, parent_comment.id)
      # IO.inspect(emotions, label: "the parent_comment")

      assert emotions.beer_count == 3
      assert user_exist_in?(user, emotions.latest_beer_users)
      assert user_exist_in?(user2, emotions.latest_beer_users)
      assert user_exist_in?(user3, emotions.latest_beer_users)
    end

    test "same user can make differcent emotions on same comment", ~m(radar user)a do
      {:ok, parent_comment} = CMS.create_comment(:radar, radar.id, mock_comment(), user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :beer, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :heart, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :orz, user)

      {:ok, %{emotions: emotions}} = ORM.find(Comment, parent_comment.id)

      assert emotions.downvote_count == 1
      assert user_exist_in?(user, emotions.latest_downvote_users)

      assert emotions.beer_count == 1
      assert user_exist_in?(user, emotions.latest_beer_users)

      assert emotions.heart_count == 1
      assert user_exist_in?(user, emotions.latest_heart_users)

      assert emotions.orz_count == 1
      assert user_exist_in?(user, emotions.latest_orz_users)

      assert emotions.pill_count == 0
      assert not user_exist_in?(user, emotions.latest_pill_users)

      assert emotions.biceps_count == 0
      assert not user_exist_in?(user, emotions.latest_biceps_users)

      assert emotions.confused_count == 0
      assert not user_exist_in?(user, emotions.latest_confused_users)
    end
  end
end
