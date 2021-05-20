defmodule GroupherServer.Test.CMS.Community.CommunityMeta do
  @moduledoc false

  use GroupherServer.TestTools

  import Helper.Utils, only: [strip_struct: 1]

  alias GroupherServer.CMS
  alias CMS.{Community, Embeds}

  alias Helper.{ORM}

  @default_meta Embeds.CommunityMeta.default_meta()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})

    {:ok, ~m(user community community_attrs)a}
  end

  describe "[cms community meta]" do
    @tag :wip2
    test "created community should have default meta ", ~m(user community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)
      assert community.meta |> strip_struct == @default_meta
    end

    @tag :wip2
    test "update legacy community should add default meta", ~m(user community)a do
      assert is_nil(community.meta)

      {:ok, community} = CMS.update_community(community.id, %{title: "new title"})
      assert community.meta |> strip_struct == @default_meta
    end

    # @tag :wip2
    # test "create a post should inc posts_count in meta" , ~m(user)a do

    # end
  end
end
