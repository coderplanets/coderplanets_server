defmodule GroupherServer.Test.Mutation.Articles.RadarEmotion do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    radar_attrs = mock_attrs(:radar, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community radar_attrs)a}
  end

  describe "[radar emotion]" do
    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      emotionToRadar(id: $id, emotion: $emotion) {
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

    test "login user can emotion to a pradar", ~m(community radar_attrs user user_conn)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      variables = %{id: radar.id, emotion: "BEER"}
      article = user_conn |> mutation_result(@emotion_query, variables, "emotionToRadar")

      assert article |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(article, ["emotions", "viewerHasBeered"])
    end

    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      undoEmotionToRadar(id: $id, emotion: $emotion) {
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

    test "login user can undo emotion to a radar", ~m(community radar_attrs user owner_conn)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _} = CMS.emotion_to_article(:radar, radar.id, :beer, user)

      variables = %{id: radar.id, emotion: "BEER"}
      article = owner_conn |> mutation_result(@emotion_query, variables, "undoEmotionToRadar")

      assert article |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(article, ["emotions", "viewerHasBeered"])
    end
  end
end
