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

  describe "post_favorites" do
    alias MastaniServer.CMS.PostFavorite

    @valid_attrs %{todo: "some todo"}
    @update_attrs %{todo: "some updated todo"}
    @invalid_attrs %{todo: nil}

    def post_favorite_fixture(attrs \\ %{}) do
      {:ok, post_favorite} =
        attrs
        |> Enum.into(@valid_attrs)
        |> CMS.create_post_favorite()

      post_favorite
    end

    test "list_post_favorites/0 returns all post_favorites" do
      post_favorite = post_favorite_fixture()
      assert CMS.list_post_favorites() == [post_favorite]
    end

    test "get_post_favorite!/1 returns the post_favorite with given id" do
      post_favorite = post_favorite_fixture()
      assert CMS.get_post_favorite!(post_favorite.id) == post_favorite
    end

    test "create_post_favorite/1 with valid data creates a post_favorite" do
      assert {:ok, %PostFavorite{} = post_favorite} = CMS.create_post_favorite(@valid_attrs)
      assert post_favorite.todo == "some todo"
    end

    test "create_post_favorite/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CMS.create_post_favorite(@invalid_attrs)
    end

    test "update_post_favorite/2 with valid data updates the post_favorite" do
      post_favorite = post_favorite_fixture()
      assert {:ok, post_favorite} = CMS.update_post_favorite(post_favorite, @update_attrs)
      assert %PostFavorite{} = post_favorite
      assert post_favorite.todo == "some updated todo"
    end

    test "update_post_favorite/2 with invalid data returns error changeset" do
      post_favorite = post_favorite_fixture()
      assert {:error, %Ecto.Changeset{}} = CMS.update_post_favorite(post_favorite, @invalid_attrs)
      assert post_favorite == CMS.get_post_favorite!(post_favorite.id)
    end

    test "delete_post_favorite/1 deletes the post_favorite" do
      post_favorite = post_favorite_fixture()
      assert {:ok, %PostFavorite{}} = CMS.delete_post_favorite(post_favorite)
      assert_raise Ecto.NoResultsError, fn -> CMS.get_post_favorite!(post_favorite.id) end
    end

    test "change_post_favorite/1 returns a post_favorite changeset" do
      post_favorite = post_favorite_fixture()
      assert %Ecto.Changeset{} = CMS.change_post_favorite(post_favorite)
    end
  end

  describe "posts_stars" do
    alias MastaniServer.CMS.PostStar

    @valid_attrs %{todo: "some todo"}
    @update_attrs %{todo: "some updated todo"}
    @invalid_attrs %{todo: nil}

    def post_star_fixture(attrs \\ %{}) do
      {:ok, post_star} =
        attrs
        |> Enum.into(@valid_attrs)
        |> CMS.create_post_star()

      post_star
    end

    test "list_post_stars/0 returns all post_stars" do
      post_star = post_star_fixture()
      assert CMS.list_post_stars() == [post_star]
    end

    test "get_post_star!/1 returns the post_star with given id" do
      post_star = post_star_fixture()
      assert CMS.get_post_star!(post_star.id) == post_star
    end

    test "create_post_star/1 with valid data creates a post_star" do
      assert {:ok, %PostStar{} = post_star} = CMS.create_post_star(@valid_attrs)
      assert post_star.todo == "some todo"
    end

    test "create_post_star/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CMS.create_post_star(@invalid_attrs)
    end

    test "update_post_star/2 with valid data updates the post_star" do
      post_star = post_star_fixture()
      assert {:ok, post_star} = CMS.update_post_star(post_star, @update_attrs)
      assert %PostStar{} = post_star
      assert post_star.todo == "some updated todo"
    end

    test "update_post_star/2 with invalid data returns error changeset" do
      post_star = post_star_fixture()
      assert {:error, %Ecto.Changeset{}} = CMS.update_post_star(post_star, @invalid_attrs)
      assert post_star == CMS.get_post_star!(post_star.id)
    end

    test "delete_post_star/1 deletes the post_star" do
      post_star = post_star_fixture()
      assert {:ok, %PostStar{}} = CMS.delete_post_star(post_star)
      assert_raise Ecto.NoResultsError, fn -> CMS.get_post_star!(post_star.id) end
    end

    test "change_post_star/1 returns a post_star changeset" do
      post_star = post_star_fixture()
      assert %Ecto.Changeset{} = CMS.change_post_star(post_star)
    end
  end

  describe "posts_comments" do
    alias MastaniServer.CMS.PostComment

    @valid_attrs %{body: "some body"}
    @update_attrs %{body: "some updated body"}
    @invalid_attrs %{body: nil}

    def post_comment_fixture(attrs \\ %{}) do
      {:ok, post_comment} =
        attrs
        |> Enum.into(@valid_attrs)
        |> CMS.create_post_comment()

      post_comment
    end

    test "list_posts_comments/0 returns all posts_comments" do
      post_comment = post_comment_fixture()
      assert CMS.list_posts_comments() == [post_comment]
    end

    test "get_post_comment!/1 returns the post_comment with given id" do
      post_comment = post_comment_fixture()
      assert CMS.get_post_comment!(post_comment.id) == post_comment
    end

    test "create_post_comment/1 with valid data creates a post_comment" do
      assert {:ok, %PostComment{} = post_comment} = CMS.create_post_comment(@valid_attrs)
      assert post_comment.body == "some body"
    end

    test "create_post_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CMS.create_post_comment(@invalid_attrs)
    end

    test "update_post_comment/2 with valid data updates the post_comment" do
      post_comment = post_comment_fixture()
      assert {:ok, post_comment} = CMS.update_post_comment(post_comment, @update_attrs)
      assert %PostComment{} = post_comment
      assert post_comment.body == "some updated body"
    end

    test "update_post_comment/2 with invalid data returns error changeset" do
      post_comment = post_comment_fixture()
      assert {:error, %Ecto.Changeset{}} = CMS.update_post_comment(post_comment, @invalid_attrs)
      assert post_comment == CMS.get_post_comment!(post_comment.id)
    end

    test "delete_post_comment/1 deletes the post_comment" do
      post_comment = post_comment_fixture()
      assert {:ok, %PostComment{}} = CMS.delete_post_comment(post_comment)
      assert_raise Ecto.NoResultsError, fn -> CMS.get_post_comment!(post_comment.id) end
    end

    test "change_post_comment/1 returns a post_comment changeset" do
      post_comment = post_comment_fixture()
      assert %Ecto.Changeset{} = CMS.change_post_comment(post_comment)
    end
  end
end
