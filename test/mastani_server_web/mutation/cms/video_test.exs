defmodule MastaniServer.Test.Mutation.Video do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.CMS

  setup do
    {:ok, video} = db_insert(:video)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, video)

    {:ok, ~m(user_conn guest_conn owner_conn video)a}
  end

  describe "[mutation video curd]" do
    @create_video_query """
    mutation(
      $title: String!,
      $poster: String!,
      $thumbnil: String!,
      $desc: String!,
      $duration: String!,
      $durationSec: Int!,
      $source: String!,
      $link: String!,
      $originalAuthor: String!,
      $originalAuthorLink: String!,
      $publishAt: String!,
      $communityId: ID!,
      $tags: [Ids]
    ) {
      createVideo(
        title: $title,
        poster: $poster,
        thumbnil: $thumbnil,
        desc: $desc,
        duration: $duration,
        durationSec: $durationSec,
        source: $source,
        link: $link,
        originalAuthor:$originalAuthor,
        originalAuthorLink: $originalAuthorLink,
        publishAt: $publishAt,
        communityId: $communityId,
        tags: $tags
      ) {
        id
        title
        desc
      }
    }
    """
    test "create video with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      video_attr = mock_attrs(:video) |> camelize_map_key

      variables = video_attr |> Map.merge(%{communityId: community.id})
      created = user_conn |> mutation_result(@create_video_query, variables, "createVideo")
      {:ok, video} = ORM.find(CMS.Video, created["id"])

      assert created["id"] == to_string(video.id)
      assert {:ok, _} = ORM.find_by(CMS.Author, user_id: user.id)
    end
  end
end
