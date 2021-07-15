defmodule GroupherServer.Test.Helper.ORM do
  use GroupherServer.TestTools

  # TODO import Service.Utils move both helper and github
  import GroupherServer.Support.Factory

  alias GroupherServer.CMS.Model.{Post, Author}
  alias GroupherServer.Accounts.Model.User
  alias Helper.ORM

  @posts_count 20
  @post_clauses %{title: "hello groupher"}

  setup do
    db_insert_multi(:post, @posts_count)
    {:ok, post} = db_insert(:post, @post_clauses)

    {:ok, post: post}
  end

  describe "[find/x find_by]" do
    test "find/2 should work, and not preload fields", %{post: post} do
      {:ok, found} = ORM.find(Post, post.id)

      assert found.id == post.id
      assert %Ecto.Association.NotLoaded{} = found.author
    end

    test "find/2 fails with {:error, reason} style" do
      result = ORM.find(Post, 15_982_398_614)

      assert {:error, _} = result
    end

    test "find/3 with preload can preload one field", %{post: post} do
      {:ok, found} = ORM.find(Post, post.id, preload: :author)

      assert found.id == post.id
      assert %Author{} = found.author
    end

    test "find/3 with preload can preload muilt fields", %{post: post} do
      {:ok, found} = ORM.find(Post, post.id, preload: [:author, :article_tags, :communities])
      # IO.inspect found
      assert %Author{} = found.author
      assert %Ecto.Association.NotLoaded{} != found.article_tags
      assert %Ecto.Association.NotLoaded{} != found.communities
    end

    test "find/3 with preload can preload nested field", %{post: post} do
      {:ok, found} = ORM.find(Post, post.id, preload: [author: :user])

      assert %Author{} = found.author
      assert %User{} = found.author.user
    end

    test "find_by/2 should find a target by given clauses" do
      {:ok, found} = ORM.find_by(Post, @post_clauses)

      assert found.title == @post_clauses.title
    end
  end

  test "count should work" do
    assert {:ok, @posts_count + 1} == ORM.count(Post)
  end

  describe "[embeds paginator]" do
    test "filter should work" do
      total_count = 100

      list =
        Enum.reduce(1..total_count, [], fn i, acc ->
          acc ++ ["i-#{i}"]
        end)

      filter = %{page: 1, size: 30}
      result = ORM.embeds_paginator(list, filter)

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == length(list)
      assert result.page_number == 1
      assert is_list(result.entries)
      assert result.entries |> List.first() == "i-1"
      assert result.entries |> List.last() == "i-30"

      filter = %{page: 4, size: 30}
      result = ORM.embeds_paginator(list, filter)

      assert result.page_number == 4
      assert result.entries |> List.first() == "i-91"
      assert result.entries |> List.last() == "i-100"
    end
  end
end
