defmodule GroupherServer.Test.CMS.Emotions.PostEmotions do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{Post, Embeds, ArticleUserEmotion}

  @default_emotions Embeds.ArticleEmotion.default_emotions()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    {:ok, post} = db_insert(:post)
    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community post post_attrs)a}
  end

  describe "[emotion in paged posts]" do
    @tag :wip2
    test "login user should got viewer has emotioned status",
         ~m(community post post_attrs user)a do
      total_count = 0
      page_number = 10
      page_size = 20

      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)
      {:ok, _} = CMS.emotion_to_article(:post, post.id, :downvote, user)

      # all_posts =
      #   Enum.reduce(0..total_count, [], fn _, acc ->
      #     {:ok, post} = CMS.create_content(community, :post, post_attrs, user)
      #     acc ++ [post]
      #   end)

      # first_comment = List.first(all_comment)

      # {:ok, _} = CMS.emotion_to_comment(first_comment.id, :downvote, user)
      # {:ok, _} = CMS.emotion_to_comment(first_comment.id, :beer, user)
      # {:ok, _} = CMS.emotion_to_comment(first_comment.id, :popcorn, user)

      {:ok, paged_articles} =
        CMS.paged_articles(:post, %{page: page_number, size: page_size}, user)

      target = Enum.find(paged_articles.entries, &(&1.id == post.id))

      IO.inspect(target.emotions, label: "target emotions")

      # target = Enum.find(paged_comments.entries, &(&1.id == first_comment.id))

      # assert target.emotions.downvote_count == 1
      # assert user_exist_in?(user, target.emotions.latest_downvote_users)
      # assert target.emotions.viewer_has_downvoteed

      # assert target.emotions.beer_count == 1
      # assert user_exist_in?(user, target.emotions.latest_beer_users)
      # assert target.emotions.viewer_has_beered

      # assert target.emotions.popcorn_count == 1
      # assert user_exist_in?(user, target.emotions.latest_popcorn_users)
      # assert target.emotions.viewer_has_popcorned
    end
  end

  describe "[basic article comment emotion]" do
    @tag :wip
    test "comment has default emotions after created", ~m(post user)a do
      parent_content = "parent comment"

      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)
      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      emotions = parent_comment.emotions |> Map.from_struct() |> Map.delete(:id)
      assert @default_emotions == emotions
    end

    @tag :wip3
    test "can make emotion to comment", ~m(post user user2)a do
      parent_content = "parent comment"
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(ArticleComment, parent_comment.id)

      assert emotions.downvote_count == 2
      assert user_exist_in?(user, emotions.latest_downvote_users)
      assert user_exist_in?(user2, emotions.latest_downvote_users)
    end

    @tag :wip3
    test "can undo emotion to comment", ~m(post user user2)a do
      parent_content = "parent comment"
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(ArticleComment, parent_comment.id)

      assert emotions.downvote_count == 2
      assert user_exist_in?(user, emotions.latest_downvote_users)
      assert user_exist_in?(user2, emotions.latest_downvote_users)

      {:ok, _} = CMS.undo_emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.undo_emotion_to_comment(parent_comment.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(ArticleComment, parent_comment.id)
      assert emotions.downvote_count == 0
      assert not user_exist_in?(user, emotions.latest_downvote_users)
      assert not user_exist_in?(user2, emotions.latest_downvote_users)
    end

    @tag :wip3
    test "same user make same emotion to same comment.", ~m(post user)a do
      parent_content = "parent comment"
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      assert parent_comment.emotions.downvote_count == 1
      assert user_exist_in?(user, parent_comment.emotions.latest_downvote_users)
    end

    @tag :wip3
    test "same user same emotion to same comment only have one user_emotion record",
         ~m(post user)a do
      parent_content = "parent comment"
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :heart, user)

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      {:ok, records} = ORM.find_all(ArticleCommentUserEmotion, %{page: 1, size: 10})
      assert records.total_count == 1

      {:ok, record} =
        ORM.find_by(ArticleCommentUserEmotion, %{
          article_comment_id: parent_comment.id,
          user_id: user.id
        })

      assert record.downvote
      assert record.heart
    end

    @tag :wip3
    test "different user can make same emotions on same comment", ~m(post user user2 user3)a do
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, "parent comment", user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :beer, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :beer, user2)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :beer, user3)

      {:ok, %{emotions: emotions}} = ORM.find(ArticleComment, parent_comment.id)
      # IO.inspect(emotions, label: "the parent_comment")

      assert emotions.beer_count == 3
      assert user_exist_in?(user, emotions.latest_beer_users)
      assert user_exist_in?(user2, emotions.latest_beer_users)
      assert user_exist_in?(user3, emotions.latest_beer_users)
    end

    @tag :wip
    test "same user can make differcent emotions on same comment", ~m(post user)a do
      parent_content = "parent comment"
      {:ok, parent_comment} = CMS.create_article_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :beer, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :heart, user)
      {:ok, _} = CMS.emotion_to_comment(parent_comment.id, :orz, user)

      {:ok, %{emotions: emotions}} = ORM.find(ArticleComment, parent_comment.id)

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
