defmodule MastaniServer.CMSTest do
  use MastaniServer.DataCase

  alias MastaniServer.CMS

  describe "cms_posts" do
    alias MastaniServer.CMS.Post

    @valid_attrs %{body: "some body", isRefined: true, isSticky: true, title: "some title", viewerCanCollect: "some viewerCanCollect", viewerCanStar: true, viewerCanWatch: "some viewerCanWatch", viewsCount: 42}
    @update_attrs %{body: "some updated body", isRefined: false, isSticky: false, title: "some updated title", viewerCanCollect: "some updated viewerCanCollect", viewerCanStar: false, viewerCanWatch: "some updated viewerCanWatch", viewsCount: 43}
    @invalid_attrs %{body: nil, isRefined: nil, isSticky: nil, title: nil, viewerCanCollect: nil, viewerCanStar: nil, viewerCanWatch: nil, viewsCount: nil}

    def post_fixture(attrs \\ %{}) do
      {:ok, post} =
        attrs
        |> Enum.into(@valid_attrs)
        |> CMS.create_post()

      post
    end

    test "list_cms_posts/0 returns all cms_posts" do
      post = post_fixture()
      assert CMS.list_cms_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert CMS.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      assert {:ok, %Post{} = post} = CMS.create_post(@valid_attrs)
      assert post.body == "some body"
      assert post.isRefined == true
      assert post.isSticky == true
      assert post.title == "some title"
      assert post.viewerCanCollect == "some viewerCanCollect"
      assert post.viewerCanStar == true
      assert post.viewerCanWatch == "some viewerCanWatch"
      assert post.viewsCount == 42
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CMS.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()
      assert {:ok, post} = CMS.update_post(post, @update_attrs)
      assert %Post{} = post
      assert post.body == "some updated body"
      assert post.isRefined == false
      assert post.isSticky == false
      assert post.title == "some updated title"
      assert post.viewerCanCollect == "some updated viewerCanCollect"
      assert post.viewerCanStar == false
      assert post.viewerCanWatch == "some updated viewerCanWatch"
      assert post.viewsCount == 43
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = CMS.update_post(post, @invalid_attrs)
      assert post == CMS.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = CMS.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> CMS.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = CMS.change_post(post)
    end
  end
end
