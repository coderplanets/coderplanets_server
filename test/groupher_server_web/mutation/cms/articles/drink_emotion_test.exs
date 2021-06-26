defmodule GroupherServer.Test.Mutation.Articles.DrinkEmotion do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    drink_attrs = mock_attrs(:drink, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community drink_attrs)a}
  end

  describe "[drink emotion]" do
    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      emotionToDrink(id: $id, emotion: $emotion) {
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

    test "login user can emotion to a pdrink", ~m(community drink_attrs user user_conn)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      variables = %{id: drink.id, emotion: "BEER"}
      article = user_conn |> mutation_result(@emotion_query, variables, "emotionToDrink")

      assert article |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(article, ["emotions", "viewerHasBeered"])
    end

    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      undoEmotionToDrink(id: $id, emotion: $emotion) {
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

    test "login user can undo emotion to a drink", ~m(community drink_attrs user owner_conn)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, _} = CMS.emotion_to_article(:drink, drink.id, :beer, user)

      variables = %{id: drink.id, emotion: "BEER"}
      article = owner_conn |> mutation_result(@emotion_query, variables, "undoEmotionToDrink")

      assert article |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(article, ["emotions", "viewerHasBeered"])
    end
  end
end
