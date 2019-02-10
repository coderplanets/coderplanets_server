defmodule MastaniServer.Test.CMS.Video do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    video_attrs = mock_attrs(:video, %{community_id: community.id})

    {:ok, ~m(user community video_attrs)a}
  end

  describe "[cms video curd]" do
    alias CMS.{Author, Community}

    test "can create video with valid attrs", ~m(user community video_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, video} = CMS.create_content(community, :video, video_attrs, user)
      assert video.title == video_attrs.title
    end

    @tag :wip
    test "created video has origial community info", ~m(user community video_attrs)a do
      {:ok, video} = CMS.create_content(community, :video, video_attrs, user)
      {:ok, found} = ORM.find(CMS.Video, video.id, preload: :origial_community)

      assert video.origial_community_id == community.id
      assert found.origial_community.id == community.id
    end

    test "add user to cms authors, if the user is not exsit in cms authors",
         ~m(user community video_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, _} = CMS.create_content(community, :video, video_attrs, user)
      {:ok, author} = ORM.find_by(Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create post with on exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:video, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_content(ivalid_community, :video, invalid_attrs, user)
    end
  end
end
