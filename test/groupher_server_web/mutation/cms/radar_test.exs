defmodule GroupherServer.Test.Mutation.Radar do
  use GroupherServer.TestTools

  # alias Helper.ORM

  setup do
    {:ok, post} = db_insert(:post)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    {:ok, ~m(user_conn guest_conn owner_conn post)a}
  end

  describe "[mutation radar posts]" do
    @create_post_query """
    mutation(
      $title: String!
      $body: String!
      $digest: String!
      $length: Int!
      $communityId: ID!
      $tags: [Ids]
      $mentionUsers: [Ids]
      $linkAddr: String
    ) {
      createPost(
        title: $title
        body: $body
        digest: $digest
        length: $length
        communityId: $communityId
        tags: $tags
        mentionUsers: $mentionUsers
        linkAddr: $linkAddr
      ) {
        title
        id
        linkAddr
        linkIcon
      }
    }
    """
    @wanqu "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/radar_source/wanqu.png"
    @default_radar "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/radar_source/default_radar.png"
    @parse_error "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/radar_source/url_parse_waning.png"

    test "create radar with known source will auto add link icon addr" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables =
        post_attr
        |> Map.merge(%{
          communityId: community.id,
          linkAddr: "https://wanqu.co/a/7237/"
        })

      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      assert created["linkIcon"] == @wanqu
      assert created["linkAddr"] == "https://wanqu.co/a/7237/"
    end

    test "create radar with unknown source will add default link icon addr" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables =
        post_attr
        |> Map.merge(%{
          communityId: community.id,
          linkAddr: "https://unknown.com"
        })

      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      assert created["linkIcon"] == @default_radar
      assert created["linkAddr"] == "https://unknown.com"
    end

    test "create radar with invalid link addr will add error link icon addr" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables =
        post_attr
        |> Map.merge(%{
          communityId: community.id,
          linkAddr: "watdjfiefejife"
        })

      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      assert created["linkIcon"] == @parse_error
      assert created["linkAddr"] == "watdjfiefejife"
    end
  end
end
