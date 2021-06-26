defmodule GroupherServer.Test.CMS.Artilces.DrinkPin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, drink} = CMS.create_article(community, :drink, mock_attrs(:drink), user)

    {:ok, ~m(user community drink)a}
  end

  describe "[cms drink pin]" do
    test "can pin a drink", ~m(community drink)a do
      {:ok, _} = CMS.pin_article(:drink, drink.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{drink_id: drink.id})

      assert pind_article.drink_id == drink.id
    end

    test "one community & thread can only pin certern count of drink", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_drink} = CMS.create_article(community, :drink, mock_attrs(:drink), user)
        {:ok, _} = CMS.pin_article(:drink, new_drink.id, community.id)
        acc
      end)

      {:ok, new_drink} = CMS.create_article(community, :drink, mock_attrs(:drink), user)
      {:error, reason} = CMS.pin_article(:drink, new_drink.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit drink", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:drink, 8848, community.id)
    end

    test "can undo pin to a drink", ~m(community drink)a do
      {:ok, _} = CMS.pin_article(:drink, drink.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:drink, drink.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{drink_id: drink.id})
    end
  end
end
