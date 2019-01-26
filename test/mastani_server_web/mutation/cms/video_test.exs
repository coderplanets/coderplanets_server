defmodule MastaniServer.Test.Mutation.Video do
  use MastaniServer.TestTools

  alias Helper.{ORM, Utils}
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

    @update_video_query """
    mutation(
      $id: ID!
      $title: String
      $poster: String
      $thumbnil: String
      $desc: String
      $duration: String
      $durationSec: Int
      $source: String
      $link: String
      $originalAuthor: String
      $originalAuthorLink: String
      $publishAt: String
      $tags: [Ids]
    ) {
      updateVideo(
        id: $id
        title: $title
        poster: $poster
        thumbnil: $thumbnil
        desc: $desc
        duration: $duration
        durationSec: $durationSec
        source: $source
        link: $link
        originalAuthor: $originalAuthor
        originalAuthorLink: $originalAuthorLink
        publishAt: $publishAt
        tags: $tags
      ) {
        id
        title
        desc
        link
      }
    }
    """
    @tag :wip
    test "update video", ~m(owner_conn video)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: video.id,
        title: "updated title #{unique_num}",
        desc: "updated body #{unique_num}",
        link: "https://xxx"
      }

      updated = owner_conn |> mutation_result(@update_video_query, variables, "updateVideo")

      assert updated["title"] == variables.title
      assert updated["desc"] == variables.desc
      assert updated["link"] == variables.link
    end

    @tag :wip
    test "can update video with tags", ~m(owner_conn video)a do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: video.id,
        title: "updated title #{unique_num}",
        tags: [%{id: tag1.id}, %{id: tag2.id}]
      }

      updated = owner_conn |> mutation_result(@update_video_query, variables, "updateVideo")
      {:ok, video} = ORM.find(CMS.Video, updated["id"], preload: :tags)
      tag_ids = video.tags |> Utils.pick_by(:id)

      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
    end

    @tag :wip
    test "can update video with refined tag", ~m(owner_conn video)a do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, tag_refined} = db_insert(:tag, %{title: "refined"})
      {:ok, tag2} = db_insert(:tag)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: video.id,
        title: "updated title #{unique_num}",
        tags: [%{id: tag_refined.id}, %{id: tag2.id}]
      }

      updated = owner_conn |> mutation_result(@update_video_query, variables, "updateVideo")
      {:ok, video} = ORM.find(CMS.Video, updated["id"], preload: :tags)
      tag_ids = video.tags |> Utils.pick_by(:id)

      assert tag_refined.id not in tag_ids
      assert tag2.id in tag_ids
    end

    @query """
    mutation($id: ID!){
      deleteVideo(id: $id) {
        id
      }
    }
    """
    test "can delete a video by video's owner", ~m(owner_conn video)a do
      deleted = owner_conn |> mutation_result(@query, %{id: video.id}, "deleteVideo")

      assert deleted["id"] == to_string(video.id)
      assert {:error, _} = ORM.find(CMS.Video, deleted["id"])
    end

    test "can delete a video by auth user", ~m(video)a do
      belongs_community_title = video.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"video.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: video.id}, "deleteVideo")

      assert deleted["id"] == to_string(video.id)
      assert {:error, _} = ORM.find(CMS.Video, deleted["id"])
    end
  end

  describe "[mutation video tag]" do
    @set_tag_query """
    mutation($thread: String!, $id: ID!, $tagId: ID! $communityId: ID!) {
      setTag(thread: $thread, id: $id, tagId: $tagId, communityId: $communityId) {
        id
        title
      }
    }
    """
    @set_refined_tag_query """
    mutation($communityId: ID!, $thread: CmsThread, $topic: String, $id: ID!) {
      setRefinedTag(
        communityId: $communityId
        thread: $thread
        topic: $topic
        id: $id
      ) {
        id
        title
      }
    }
    """
    test "auth user can set a valid tag to video", ~m(video)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "video", community: community})

      passport_rules = %{community.title => %{"video.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{thread: "VIDEO", id: video.id, tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")
      {:ok, found} = ORM.find(CMS.Video, video.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
    end

    test "can not set refined tag to video", ~m(video)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "video", community: community, title: "refined"})

      passport_rules = %{community.title => %{"video.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: video.id, tagId: tag.id, communityId: community.id}

      assert rule_conn |> mutation_get_error?(@set_tag_query, variables)
    end

    test "auth user can set refined tag to video", ~m(video)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "video", community: community, title: "refined"})

      passport_rules = %{community.title => %{"video.refinedtag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: video.id, communityId: community.id, thread: "VIDEO"}
      rule_conn |> mutation_result(@set_refined_tag_query, variables, "setRefinedTag")
      {:ok, found} = ORM.find(CMS.Video, video.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
    end

    test "can set multi tag to a video", ~m(video)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{community: community, thread: "video"})
      {:ok, tag2} = db_insert(:tag, %{community: community, thread: "video"})

      passport_rules = %{community.title => %{"video.tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{thread: "VIDEO", id: video.id, tagId: tag.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables, "setTag")

      variables2 = %{thread: "VIDEO", id: video.id, tagId: tag2.id, communityId: community.id}
      rule_conn |> mutation_result(@set_tag_query, variables2, "setTag")

      {:ok, found} = ORM.find(CMS.Video, video.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id in assoc_tags
      assert tag2.id in assoc_tags
    end

    @unset_refined_tag_query """
    mutation($communityId: ID!, $thread: CmsThread, $topic: String, $id: ID!) {
      unsetRefinedTag(
        communityId: $communityId
        thread: $thread
        topic: $topic
        id: $id
      ) {
        id
        title
      }
    }
    """
    test "can unset refined tag to a video", ~m(video)a do
      {:ok, community} = db_insert(:community)
      {:ok, tag} = db_insert(:tag, %{thread: "video", community: community, title: "refined"})

      passport_rules = %{community.title => %{"video.refinedtag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{id: video.id, communityId: community.id, thread: "VIDEO"}
      rule_conn |> mutation_result(@set_refined_tag_query, variables, "setRefinedTag")

      variables = %{id: video.id, communityId: community.id, thread: "VIDEO"}
      rule_conn |> mutation_result(@unset_refined_tag_query, variables, "unsetRefinedTag")

      {:ok, found} = ORM.find(CMS.Video, video.id, preload: :tags)

      assoc_tags = found.tags |> Enum.map(& &1.id)
      assert tag.id not in assoc_tags
    end
  end
end
