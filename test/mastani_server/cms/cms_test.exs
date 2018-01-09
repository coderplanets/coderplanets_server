defmodule MastaniServer.CMSTest do
  use MastaniServer.DataCase

  alias MastaniServer.CMS

  describe "cms_posts" do
    alias MastaniServer.CMS.Post

    @valid_attrs %{
      body: "some body",
      isRefined: true,
      isSticky: true,
      title: "some title",
      viewerCanCollect: "some viewerCanCollect",
      viewerCanStar: true,
      viewerCanWatch: "some viewerCanWatch",
      viewsCount: 42
    }
    @update_attrs %{
      body: "some updated body",
      isRefined: false,
      isSticky: false,
      title: "some updated title",
      viewerCanCollect: "some updated viewerCanCollect",
      viewerCanStar: false,
      viewerCanWatch: "some updated viewerCanWatch",
      viewsCount: 43
    }
    @invalid_attrs %{
      body: nil,
      isRefined: nil,
      isSticky: nil,
      title: nil,
      viewerCanCollect: nil,
      viewerCanStar: nil,
      viewerCanWatch: nil,
      viewsCount: nil
    }

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

  describe "cms_authors" do
    alias MastaniServer.CMS.Author

    @valid_attrs %{role: "some role"}
    @update_attrs %{role: "some updated role"}
    @invalid_attrs %{role: nil}

    def author_fixture(attrs \\ %{}) do
      {:ok, author} =
        attrs
        |> Enum.into(@valid_attrs)
        |> CMS.create_author()

      author
    end

    test "list_cms_authors/0 returns all cms_authors" do
      author = author_fixture()
      assert CMS.list_cms_authors() == [author]
    end

    test "get_author!/1 returns the author with given id" do
      author = author_fixture()
      assert CMS.get_author!(author.id) == author
    end

    test "create_author/1 with valid data creates a author" do
      assert {:ok, %Author{} = author} = CMS.create_author(@valid_attrs)
      assert author.role == "some role"
    end

    test "create_author/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CMS.create_author(@invalid_attrs)
    end

    test "update_author/2 with valid data updates the author" do
      author = author_fixture()
      assert {:ok, author} = CMS.update_author(author, @update_attrs)
      assert %Author{} = author
      assert author.role == "some updated role"
    end

    test "update_author/2 with invalid data returns error changeset" do
      author = author_fixture()
      assert {:error, %Ecto.Changeset{}} = CMS.update_author(author, @invalid_attrs)
      assert author == CMS.get_author!(author.id)
    end

    test "delete_author/1 deletes the author" do
      author = author_fixture()
      assert {:ok, %Author{}} = CMS.delete_author(author)
      assert_raise Ecto.NoResultsError, fn -> CMS.get_author!(author.id) end
    end

    test "change_author/1 returns a author changeset" do
      author = author_fixture()
      assert %Ecto.Changeset{} = CMS.change_author(author)
    end
  end

  describe "comments" do
    alias MastaniServer.CMS.Comment

    @valid_attrs %{body: "some body"}
    @update_attrs %{body: "some updated body"}
    @invalid_attrs %{body: nil}

    def comment_fixture(attrs \\ %{}) do
      {:ok, comment} =
        attrs
        |> Enum.into(@valid_attrs)
        |> CMS.create_comment()

      comment
    end

    test "list_comments/0 returns all comments" do
      comment = comment_fixture()
      assert CMS.list_comments() == [comment]
    end

    test "get_comment!/1 returns the comment with given id" do
      comment = comment_fixture()
      assert CMS.get_comment!(comment.id) == comment
    end

    test "create_comment/1 with valid data creates a comment" do
      assert {:ok, %Comment{} = comment} = CMS.create_comment(@valid_attrs)
      assert comment.body == "some body"
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CMS.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      assert {:ok, comment} = CMS.update_comment(comment, @update_attrs)
      assert %Comment{} = comment
      assert comment.body == "some updated body"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = CMS.update_comment(comment, @invalid_attrs)
      assert comment == CMS.get_comment!(comment.id)
    end

    test "delete_comment/1 deletes the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{}} = CMS.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> CMS.get_comment!(comment.id) end
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = CMS.change_comment(comment)
    end
  end
end
