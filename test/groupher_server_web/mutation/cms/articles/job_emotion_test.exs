defmodule GroupherServer.Test.Mutation.Articles.JobEmotion do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community job_attrs)a}
  end

  describe "[job emotion]" do
    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      emotionToJob(id: $id, emotion: $emotion) {
        id
        emotions {
          beerCount
          viewerHasBeered
          latestBeerUsers {
            login
            nickname
          }
        }
      }
    }
    """

    test "login user can emotion to a pjob", ~m(community job_attrs user user_conn)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      variables = %{id: job.id, emotion: "BEER"}
      article = user_conn |> mutation_result(@emotion_query, variables, "emotionToJob")

      assert article |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(article, ["emotions", "viewerHasBeered"])
    end

    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      undoEmotionToJob(id: $id, emotion: $emotion) {
        id
        emotions {
          beerCount
          viewerHasBeered
          latestBeerUsers {
            login
            nickname
          }
        }
      }
    }
    """

    test "login user can undo emotion to a job", ~m(community job_attrs user owner_conn)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.emotion_to_article(:job, job.id, :beer, user)

      variables = %{id: job.id, emotion: "BEER"}
      article = owner_conn |> mutation_result(@emotion_query, variables, "undoEmotionToJob")

      assert article |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(article, ["emotions", "viewerHasBeered"])
    end
  end
end
