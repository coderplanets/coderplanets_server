defmodule GroupherServer.Test.Mutation.Articles.WorksEmotion do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    works_attrs = mock_attrs(:works, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community works_attrs)a}
  end

  describe "[works emotion]" do
    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      emotionToWorks(id: $id, emotion: $emotion) {
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

    test "login user can emotion to a pworks", ~m(community works_attrs user user_conn)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      variables = %{id: works.id, emotion: "BEER"}
      article = user_conn |> mutation_result(@emotion_query, variables, "emotionToWorks")

      assert article |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(article, ["emotions", "viewerHasBeered"])
    end

    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      undoEmotionToWorks(id: $id, emotion: $emotion) {
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

    test "login user can undo emotion to a works", ~m(community works_attrs user owner_conn)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _} = CMS.emotion_to_article(:works, works.id, :beer, user)

      variables = %{id: works.id, emotion: "BEER"}
      article = owner_conn |> mutation_result(@emotion_query, variables, "undoEmotionToWorks")

      assert article |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(article, ["emotions", "viewerHasBeered"])
    end
  end
end
