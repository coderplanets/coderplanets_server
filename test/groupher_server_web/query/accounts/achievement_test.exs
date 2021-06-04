defmodule GroupherServer.Test.Query.Account.Achievement do
  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{Accounts, CMS}
  alias CMS.Model.Post

  alias Helper.ORM

  @follow_weight get_config(:general, :user_achieve_follow_weight)
  @collect_weight get_config(:general, :user_achieve_collect_weight)
  # @upvote_weight get_config(:general, :user_achieve_upvote_weight)

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account get acheiveements]" do
    @query """
    query($login: String!) {
      user(login: $login) {
        id
        achievement {
          reputation
          articlesUpvotesCount
          articlesCollectsCount
          sourceContribute {
            web
            server
          }
        }
      }
    }
    """

    test "empty user should get empty achievement", ~m(guest_conn user)a do
      variables = %{login: user.login}

      results = guest_conn |> query_result(@query, variables, "user")
      assert results["achievement"] !== nil
    end
  end

  describe "[account editable-communities]" do
    @query """
    query($login: String, $filter: PagedFilter!) {
      editableCommunities(login: $login, filter: $filter) {
        entries {
          id
          logo
          title
          raw
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "can get user's empty editable communities list", ~m(guest_conn user)a do
      variables = %{login: user.login, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "editableCommunities")

      assert results |> is_valid_pagination?(:empty)
    end

    test "can get user's editable communities list when user is editor", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, community2} = db_insert(:community)

      title = "chief editor"
      {:ok, _} = CMS.set_editor(community, title, user)
      {:ok, _} = CMS.set_editor(community2, title, user)

      variables = %{login: user.login, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "editableCommunities")

      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(community.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(community2.id)))
    end
  end

  describe "[account follow achieveMent]" do
    @query """
    query($login: String!) {
      user(login: $login) {
        id
        followersCount
        followingsCount
        achievement {
          reputation
        }
      }
    }
    """
    test "inc user's achievement after user got followed", ~m(guest_conn user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)
      {:ok, user4} = db_insert(:user)

      user2 |> Accounts.follow(user)
      user |> Accounts.follow(user2)
      user3 |> Accounts.follow(user2)
      user3 |> Accounts.follow(user4)

      variables = %{login: user2.login}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results |> Map.get("followersCount") == 2
      assert results["achievement"] |> Map.get("reputation") == 2 * @follow_weight
    end

    test "minus user's achievement after user get undo followed", ~m(guest_conn user)a do
      total_count = 10
      {:ok, users} = db_insert_multi(:user, total_count)

      Enum.each(users, fn fan ->
        {:ok, _} = fan |> Accounts.follow(user)
      end)

      ramdom_fan = users |> Enum.shuffle() |> List.first()
      ramdom_fan |> Accounts.undo_follow(user)

      variables = %{login: user.login}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results |> Map.get("followersCount") == total_count - 1

      assert results["achievement"] |> Map.get("reputation") == @follow_weight * (total_count - 1)
    end
  end

  describe "[account collect achieveMent]" do
    alias GroupherServer.CMS

    @query """
    query($login: String!) {
      user(login: $login) {
        id
        achievement {
          reputation
          articlesCollectsCount
        }
      }
    }
    """

    test "inc user's achievement after user's post got collected", ~m(guest_conn user)a do
      {:ok, post} = db_insert(:post)
      {:ok, _article_collect} = CMS.collect_article(:post, post.id, user)

      {:ok, post} = Post |> ORM.find(post.id, preload: [author: :user])
      author_user_login = post.author.user.login

      variables = %{login: author_user_login}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results["achievement"] |> Map.get("articlesCollectsCount") == 1
      assert results["achievement"] |> Map.get("reputation") == @collect_weight
    end

    test "minus user's acheiveements after user's post's collect cancled", ~m(guest_conn)a do
      total_count = 10
      {:ok, post} = db_insert(:post)
      {:ok, users} = db_insert_multi(:user, total_count)

      Enum.each(users, fn user ->
        {:ok, _article_collect} = CMS.collect_article(:post, post.id, user)
      end)

      {:ok, post} = Post |> ORM.find(post.id, preload: [author: :user])
      author_user_login = post.author.user.login

      user = users |> Enum.shuffle() |> List.first()
      {:ok, _article_collect} = CMS.undo_collect_article(:post, post.id, user)

      variables = %{login: author_user_login}
      results = guest_conn |> query_result(@query, variables, "user")

      assert results["achievement"] |> Map.get("articlesCollectsCount") == total_count - 1

      assert results["achievement"] |> Map.get("reputation") ==
               @collect_weight * total_count - @collect_weight
    end
  end
end
