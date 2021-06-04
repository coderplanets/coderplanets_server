defmodule GroupherServer.Test.CMS.Emotions.RepoEmotions do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Repo, Embeds, ArticleUserEmotion}

  @default_emotions Embeds.ArticleEmotion.default_emotions()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    repo_attrs = mock_attrs(:repo, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community repo_attrs)a}
  end

  describe "[emotion in paged repos]" do
    test "login user should got viewer has emotioned status",
         ~m(community repo_attrs user)a do
      total_count = 10
      page_number = 10
      page_size = 20

      all_repos =
        Enum.reduce(0..total_count, [], fn _, acc ->
          {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
          acc ++ [repo]
        end)

      random_repo = all_repos |> Enum.at(3)

      {:ok, _} = CMS.emotion_to_article(:repo, random_repo.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:repo, random_repo.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:repo, random_repo.id, :popcorn, user)

      {:ok, paged_articles} =
        CMS.paged_articles(:repo, %{page: page_number, size: page_size}, user)

      target = Enum.find(paged_articles.entries, &(&1.id == random_repo.id))

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

  describe "[basic article emotion]" do
    test "repo has default emotions after created", ~m(community repo_attrs user)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      emotions = repo.emotions |> Map.from_struct() |> Map.delete(:id)
      assert @default_emotions == emotions
    end

    test "can make emotion to repo", ~m(community repo_attrs user user2)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Repo, repo.id)

      assert emotions.downvote_count == 2
      assert user_exist_in?(user, emotions.latest_downvote_users)
      assert user_exist_in?(user2, emotions.latest_downvote_users)
    end

    test "can undo emotion to repo", ~m(community repo_attrs user user2)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user2)

      {:ok, _} = CMS.undo_emotion_to_article(:repo, repo.id, :downvote, user)
      {:ok, _} = CMS.undo_emotion_to_article(:repo, repo.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Repo, repo.id)

      assert emotions.downvote_count == 0
      assert not user_exist_in?(user, emotions.latest_downvote_users)
      assert not user_exist_in?(user2, emotions.latest_downvote_users)
    end

    test "same user make same emotion to same repo.", ~m(community repo_attrs user)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user)

      {:ok, repo} = ORM.find(Repo, repo.id)

      assert repo.emotions.downvote_count == 1
      assert user_exist_in?(user, repo.emotions.latest_downvote_users)
    end

    test "same user same emotion to same repo only have one user_emotion record",
         ~m(community repo_attrs user)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :heart, user)

      {:ok, repo} = ORM.find(Repo, repo.id)

      {:ok, records} = ORM.find_all(ArticleUserEmotion, %{page: 1, size: 10})
      assert records.total_count == 1

      {:ok, record} = ORM.find_by(ArticleUserEmotion, %{repo_id: repo.id, user_id: user.id})
      assert record.downvote
      assert record.heart
    end

    test "different user can make same emotions on same repo",
         ~m(community repo_attrs user user2 user3)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :beer, user2)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :beer, user3)

      {:ok, %{emotions: emotions}} = ORM.find(Repo, repo.id)

      assert emotions.beer_count == 3
      assert user_exist_in?(user, emotions.latest_beer_users)
      assert user_exist_in?(user2, emotions.latest_beer_users)
      assert user_exist_in?(user3, emotions.latest_beer_users)
    end

    test "same user can make differcent emotions on same repo", ~m(community repo_attrs user)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :heart, user)
      {:ok, _} = CMS.emotion_to_article(:repo, repo.id, :orz, user)

      {:ok, %{emotions: emotions}} = ORM.find(Repo, repo.id)

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
