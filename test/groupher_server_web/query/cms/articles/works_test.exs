defmodule GroupherServer.Test.Query.Articles.Works do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, works} = db_insert(:works)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    works_attrs = mock_attrs(:works, %{community_id: community.id})

    {:ok, ~m(user_conn guest_conn works user community works_attrs)a}
  end

  @query """
  query($id: ID!) {
    works(id: $id) {
      id
      title
      meta {
        isEdited
        isLegal
        illegalReason
        illegalWords
      }
      isArchived
      archivedAt
    }
  }
  """
  test "basic graphql query on works with logined user",
       ~m(user_conn community user works_attrs)a do
    {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

    variables = %{id: works.id}
    results = user_conn |> query_result(@query, variables, "works")

    assert results["id"] == to_string(works.id)
    assert is_valid_kv?(results, "title", :string)

    assert results["meta"] == %{
             "isEdited" => false,
             "illegalReason" => [],
             "illegalWords" => [],
             "isLegal" => true
           }

    assert length(Map.keys(results)) == 5
  end

  test "basic graphql query on illegal audit works with logined user",
       ~m(user_conn community user works_attrs)a do
    {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

    {:ok, works} =
      CMS.set_article_illegal(
        works,
        %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        }
      )

    variables = %{id: works.id}
    results = user_conn |> query_result(@query, variables, "works")

    assert not results["meta"]["isLegal"]
  end

  test "basic graphql query on audit filed works with logined user",
       ~m(user_conn community user works_attrs)a do
    {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

    {:ok, works} = CMS.set_article_audit_failed(works, %{})

    variables = %{id: works.id}
    results = user_conn |> query_result(@query, variables, "works")

    assert results["id"] == to_string(works.id)
    assert is_valid_kv?(results, "title", :string)

    assert results["meta"]["isLegal"]
  end

  test "basic graphql query on works with stranger(unloged user)", ~m(guest_conn works)a do
    variables = %{id: works.id}
    results = guest_conn |> query_result(@query, variables, "works")

    assert results["id"] == to_string(works.id)
    assert is_valid_kv?(results, "title", :string)
  end

  test "pending state should in meta", ~m(guest_conn user_conn community user works_attrs)a do
    {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
    variables = %{id: works.id}
    results = user_conn |> query_result(@query, variables, "works")

    assert results |> get_in(["meta", "isLegal"])
    assert results |> get_in(["meta", "illegalReason"]) == []
    assert results |> get_in(["meta", "illegalWords"]) == []

    results = guest_conn |> query_result(@query, variables, "works")
    assert results |> get_in(["meta", "isLegal"])
    assert results |> get_in(["meta", "illegalReason"]) == []
    assert results |> get_in(["meta", "illegalWords"]) == []

    {:ok, _} =
      CMS.set_article_illegal(:works, works.id, %{
        is_legal: false,
        illegal_reason: ["some-reason"],
        illegal_words: ["some-word"]
      })

    results = user_conn |> query_result(@query, variables, "works")

    assert not get_in(results, ["meta", "isLegal"])
    assert results |> get_in(["meta", "illegalReason"]) == ["some-reason"]
    assert results |> get_in(["meta", "illegalWords"]) == ["some-word"]
  end
end
