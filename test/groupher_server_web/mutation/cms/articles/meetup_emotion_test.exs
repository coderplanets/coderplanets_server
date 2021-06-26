defmodule GroupherServer.Test.Mutation.Articles.MeetupEmotion do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community meetup_attrs)a}
  end

  describe "[meetup emotion]" do
    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      emotionToMeetup(id: $id, emotion: $emotion) {
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

    test "login user can emotion to a pmeetup", ~m(community meetup_attrs user user_conn)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      variables = %{id: meetup.id, emotion: "BEER"}
      article = user_conn |> mutation_result(@emotion_query, variables, "emotionToMeetup")

      assert article |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(article, ["emotions", "viewerHasBeered"])
    end

    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      undoEmotionToMeetup(id: $id, emotion: $emotion) {
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

    test "login user can undo emotion to a meetup", ~m(community meetup_attrs user owner_conn)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.emotion_to_article(:meetup, meetup.id, :beer, user)

      variables = %{id: meetup.id, emotion: "BEER"}
      article = owner_conn |> mutation_result(@emotion_query, variables, "undoEmotionToMeetup")

      assert article |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(article, ["emotions", "viewerHasBeered"])
    end
  end
end
