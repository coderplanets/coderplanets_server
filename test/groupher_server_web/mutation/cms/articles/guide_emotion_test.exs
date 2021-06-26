defmodule GroupherServer.Test.Mutation.Articles.GuideEmotion do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guide_attrs = mock_attrs(:guide, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community guide_attrs)a}
  end

  describe "[guide emotion]" do
    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      emotionToGuide(id: $id, emotion: $emotion) {
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

    test "login user can emotion to a pguide", ~m(community guide_attrs user user_conn)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      variables = %{id: guide.id, emotion: "BEER"}
      article = user_conn |> mutation_result(@emotion_query, variables, "emotionToGuide")

      assert article |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(article, ["emotions", "viewerHasBeered"])
    end

    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      undoEmotionToGuide(id: $id, emotion: $emotion) {
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

    test "login user can undo emotion to a guide", ~m(community guide_attrs user owner_conn)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _} = CMS.emotion_to_article(:guide, guide.id, :beer, user)

      variables = %{id: guide.id, emotion: "BEER"}
      article = owner_conn |> mutation_result(@emotion_query, variables, "undoEmotionToGuide")

      assert article |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(article, ["emotions", "viewerHasBeered"])
    end
  end
end
