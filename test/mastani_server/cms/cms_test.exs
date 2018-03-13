defmodule MastaniServer.CMSTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  alias MastaniServer.CMS
  alias MastaniServer.Accounts
  alias MastaniServer.Repo

  @valid_user %{
    username: "mydearxym",
    nickname: "simon",
    bio: "bio",
    company: "infomedia"
  }
  # alias MastaniServer.CMS
  setup do
    # TODO: token
    db_insert(:user, @valid_user)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer fake-token")

    {:ok, conn: conn}
  end

  describe "cms_community" do
    test "create a community with a existing user" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

      community_attr = %{
        title: "elixir community",
        desc: "function pragraming for everyone",
        user_id: user.id
      }

      assert Repo.get_by(CMS.Community, title: "elixir community") == nil
      {:ok, community} = CMS.create_community(community_attr)

      assert community.title == community_attr.title
    end

    test "create a community with a empty title fails" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

      invalid_community_attr = %{
        title: "",
        desc: "function pragraming for everyone",
        user_id: user.id
      }

      assert {:error, %Ecto.Changeset{}} = CMS.create_community(invalid_community_attr)
    end

    test "create a community with a non-exist user fails" do
      community_attr = %{
        title: "elixir community",
        desc: "function pragraming for everyone",
        user_id: 10000
      }

      assert {:error, _} = CMS.create_community(community_attr)
    end
  end

  describe "cms_posts" do
    test "post staff " do
      # ...
      true
    end

    # test "create a post" do
    # attrs = %{
    # title: "test title",
    # body: "test body",
    # digest: "test digest",
    # length: 20,
    # community: "js",
    # }

    # create_content(part, %Author{} = author, attrs \\ %{})

    # CMS.create_content(:post, )
    # assert true == true
    # end

    # @valid_attrs %{
    # body: "some body",
    # isRefined: true,
    # isSticky: true,
    # title: "some title",
    # viewerCanCollect: "some viewerCanCollect",
    # viewerCanStar: true,
    # viewerCanWatch: "some viewerCanWatch",
    # viewsCount: 42
    # }
    # @update_attrs %{
    # body: "some updated body",
    # isRefined: false,
    # isSticky: false,
    # title: "some updated title",
    # viewerCanCollect: "some updated viewerCanCollect",
    # viewerCanStar: false,
    # viewerCanWatch: "some updated viewerCanWatch",
    # viewsCount: 43
    # }
    # @invalid_attrs %{
    # body: nil,
    # isRefined: nil,
    # isSticky: nil,
    # title: nil,
    # viewerCanCollect: nil,
    # viewerCanStar: nil,
    # viewerCanWatch: nil,
    # viewsCount: nil
    # }

    # def post_fixture(attrs \\ %{}) do
    # {:ok, post} =
    # attrs
    # |> Enum.into(@valid_attrs)
    # |> CMS.create_post()

    # post
    # end

    # test "list_cms_posts/0 returns all cms_posts" do
    # post = post_fixture()
    # assert CMS.list_cms_posts() == [post]
    # end

    # test "get_post!/1 returns the post with given id" do
    # post = post_fixture()
    # assert CMS.get_post!(post.id) == post
    # end

    # test "create_post/1 with valid data creates a post" do
    # assert {:ok, %Post{} = post} = CMS.create_post(@valid_attrs)
    # assert post.body == "some body"
    # assert post.isRefined == true
    # assert post.isSticky == true
    # assert post.title == "some title"
    # assert post.viewerCanCollect == "some viewerCanCollect"
    # assert post.viewerCanStar == true
    # assert post.viewerCanWatch == "some viewerCanWatch"
    # assert post.viewsCount == 42
    # end

    # test "create_post/1 with invalid data returns error changeset" do
    # assert {:error, %Ecto.Changeset{}} = CMS.create_post(@invalid_attrs)
    # end

    # test "update_post/2 with valid data updates the post" do
    # post = post_fixture()
    # assert {:ok, post} = CMS.update_post(post, @update_attrs)
    # assert %Post{} = post
    # assert post.body == "some updated body"
    # assert post.isRefined == false
    # assert post.isSticky == false
    # assert post.title == "some updated title"
    # assert post.viewerCanCollect == "some updated viewerCanCollect"
    # assert post.viewerCanStar == false
    # assert post.viewerCanWatch == "some updated viewerCanWatch"
    # assert post.viewsCount == 43
    # end

    # test "update_post/2 with invalid data returns error changeset" do
    # post = post_fixture()
    # assert {:error, %Ecto.Changeset{}} = CMS.update_post(post, @invalid_attrs)
    # assert post == CMS.get_post!(post.id)
    # end

    # test "delete_post/1 deletes the post" do
    # post = post_fixture()
    # assert {:ok, %Post{}} = CMS.delete_post(post)
    # assert_raise Ecto.NoResultsError, fn -> CMS.get_post!(post.id) end
    # end

    # test "change_post/1 returns a post changeset" do
    # post = post_fixture()
    # assert %Ecto.Changeset{} = CMS.change_post(post)
    # end
  end
end
