defmodule GroupherServer.Test.CMS do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts.User
  alias GroupherServer.CMS
  alias CMS.Community

  alias Helper.{Certification, ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, category} = db_insert(:category)
    tag_attrs = mock_attrs(:tag)

    {:ok, ~m(user community category tag_attrs)a}
  end

  describe "[cms tag]" do
    @tag :wip2
    test "create article tag with valid data", ~m(community tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, tag_attrs, user)
      assert article_tag.title == tag_attrs.title
    end

    @tag :wip2
    test "can update an article tag", ~m(community tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, tag_attrs, user)

      new_attrs = tag_attrs |> Map.merge(%{title: "new title"})

      {:ok, article_tag} = CMS.update_article_tag(article_tag.id, new_attrs)
      assert article_tag.title == "new title"
    end

    @tag :wip2
    test "create article tag with non-exsit community fails", ~m(tag_attrs user)a do
      assert {:error, _} =
               CMS.create_article_tag(%Community{id: non_exsit_id()}, :post, tag_attrs, user)
    end
  end
end
