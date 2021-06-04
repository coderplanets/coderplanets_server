defmodule GroupherServer.Test.CMS.Emotions.JobEmotions do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Job, Embeds, ArticleUserEmotion}

  @default_emotions Embeds.ArticleEmotion.default_emotions()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community job_attrs)a}
  end

  describe "[emotion in paged jobs]" do
    test "login user should got viewer has emotioned status",
         ~m(community job_attrs user)a do
      total_count = 10
      page_number = 10
      page_size = 20

      all_jobs =
        Enum.reduce(0..total_count, [], fn _, acc ->
          {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
          acc ++ [job]
        end)

      random_job = all_jobs |> Enum.at(3)

      {:ok, _} = CMS.emotion_to_article(:job, random_job.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:job, random_job.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:job, random_job.id, :popcorn, user)

      {:ok, paged_articles} =
        CMS.paged_articles(:job, %{page: page_number, size: page_size}, user)

      target = Enum.find(paged_articles.entries, &(&1.id == random_job.id))

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
    test "job has default emotions after created", ~m(community job_attrs user)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      emotions = job.emotions |> Map.from_struct() |> Map.delete(:id)
      assert @default_emotions == emotions
    end

    test "can make emotion to job", ~m(community job_attrs user user2)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Job, job.id)

      assert emotions.downvote_count == 2
      assert user_exist_in?(user, emotions.latest_downvote_users)
      assert user_exist_in?(user2, emotions.latest_downvote_users)
    end

    test "can undo emotion to job", ~m(community job_attrs user user2)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user2)

      {:ok, _} = CMS.undo_emotion_to_article(:job, job.id, :downvote, user)
      {:ok, _} = CMS.undo_emotion_to_article(:job, job.id, :downvote, user2)

      {:ok, %{emotions: emotions}} = ORM.find(Job, job.id)

      assert emotions.downvote_count == 0
      assert not user_exist_in?(user, emotions.latest_downvote_users)
      assert not user_exist_in?(user2, emotions.latest_downvote_users)
    end

    test "same user make same emotion to same job.", ~m(community job_attrs user)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user)

      {:ok, job} = ORM.find(Job, job.id)

      assert job.emotions.downvote_count == 1
      assert user_exist_in?(user, job.emotions.latest_downvote_users)
    end

    test "same user same emotion to same job only have one user_emotion record",
         ~m(community job_attrs user)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :heart, user)

      {:ok, job} = ORM.find(Job, job.id)

      {:ok, records} = ORM.find_all(ArticleUserEmotion, %{page: 1, size: 10})
      assert records.total_count == 1

      {:ok, record} = ORM.find_by(ArticleUserEmotion, %{job_id: job.id, user_id: user.id})
      assert record.downvote
      assert record.heart
    end

    test "different user can make same emotions on same job",
         ~m(community job_attrs user user2 user3)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:job, job.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :beer, user2)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :beer, user3)

      {:ok, %{emotions: emotions}} = ORM.find(Job, job.id)

      assert emotions.beer_count == 3
      assert user_exist_in?(user, emotions.latest_beer_users)
      assert user_exist_in?(user2, emotions.latest_beer_users)
      assert user_exist_in?(user3, emotions.latest_beer_users)
    end

    test "same user can make differcent emotions on same job", ~m(community job_attrs user)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :downvote, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :beer, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :heart, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :orz, user)

      {:ok, %{emotions: emotions}} = ORM.find(Job, job.id)

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
