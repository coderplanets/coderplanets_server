defmodule GroupherServer.Test.Mutation.Articles.BlogEmotion do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community blog_attrs)a}
  end

  describe "[blog emotion]" do
    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      emotionToBlog(id: $id, emotion: $emotion) {
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

    test "login user can emotion to a pblog", ~m(community blog_attrs user user_conn)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      variables = %{id: blog.id, emotion: "BEER"}
      article = user_conn |> mutation_result(@emotion_query, variables, "emotionToBlog")

      assert article |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(article, ["emotions", "viewerHasBeered"])
    end

    @emotion_query """
    mutation($id: ID!, $emotion: ArticleEmotion!) {
      undoEmotionToBlog(id: $id, emotion: $emotion) {
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

    test "login user can undo emotion to a blog", ~m(community blog_attrs user owner_conn)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _} = CMS.emotion_to_article(:blog, blog.id, :beer, user)

      variables = %{id: blog.id, emotion: "BEER"}
      article = owner_conn |> mutation_result(@emotion_query, variables, "undoEmotionToBlog")

      assert article |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(article, ["emotions", "viewerHasBeered"])
    end
  end
end
