defmodule GroupherServer.Test.Mutation.PublishThrottle do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.Accounts.Model.User
  alias GroupherServer.Statistics

  @throttle_interval get_config(:general, :publish_throttle_interval_minutes)
  @hour_limit get_config(:general, :publish_throttle_hour_limit)
  @day_total get_config(:general, :publish_throttle_day_limit)
  # alias Helper.ORM

  setup do
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(user_conn guest_conn community)a}
  end

  @create_post_query """
  mutation(
    $title: String!
    $body: String!
    $communityId: ID!
  ) {
    createPost(
      title: $title
      body: $body
      communityId: $communityId
    ) {
      title
      id
    }
  }
  """
  test "user first create content should success", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = mock_attrs(:post) |> Map.merge(%{communityId: community.id})
    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")
  end

  test "user create 2 content with valid inverval time success", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = mock_attrs(:post) |> Map.merge(%{communityId: community.id})
    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")

    Statistics.mock_throttle_attr(
      :last_publish_time,
      %User{id: user.id},
      minutes: -@throttle_interval
    )

    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")
  end

  test "root create multi content with invalid inverval time success", ~m(community)a do
    {:ok, user} = db_insert(:user)
    passport_rules = %{"root" => true}
    rule_conn = simu_conn(:user, cms: passport_rules)
    variables = mock_attrs(:post) |> Map.merge(%{communityId: community.id})

    created = rule_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")

    created = rule_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")

    Statistics.mock_throttle_attr(
      :last_publish_time,
      %User{id: user.id},
      minutes: -(@throttle_interval - 1)
    )

    created = rule_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")
  end

  test "user create multi content with invalid inverval time", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)
    variables = mock_attrs(:post) |> Map.merge(%{communityId: community.id})

    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")

    assert user_conn
           |> mutation_get_error?(@create_post_query, variables, ecode(:throttle_inverval))

    Statistics.mock_throttle_attr(
      :last_publish_time,
      %User{id: user.id},
      minutes: -(@throttle_interval - 1)
    )

    assert user_conn
           |> mutation_get_error?(@create_post_query, variables, ecode(:throttle_inverval))
  end

  test "user create multi content with invalid hour_count fails", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = mock_attrs(:post) |> Map.merge(%{communityId: community.id})
    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")

    Statistics.mock_throttle_attr(
      :last_publish_time,
      %User{id: user.id},
      minutes: -@throttle_interval
    )

    Statistics.mock_throttle_attr(
      :hour_count,
      %User{id: user.id},
      count: @hour_limit
    )

    assert user_conn
           |> mutation_get_error?(@create_post_query, variables, ecode(:throttle_hour))
  end

  test "user create multi content with valid hour count success in next hour", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = mock_attrs(:post) |> Map.merge(%{communityId: community.id})
    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")

    Statistics.mock_throttle_attr(
      :last_publish_time,
      %User{id: user.id},
      minutes: -@throttle_interval
    )

    Statistics.mock_throttle_attr(
      :hour_count,
      %User{id: user.id},
      count: @hour_limit
    )

    assert user_conn
           |> mutation_get_error?(@create_post_query, variables, ecode(:throttle_hour))

    Statistics.mock_throttle_attr(
      :publish_hour,
      %User{id: user.id},
      hours: -1
    )

    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")
  end

  test "user create multi content with invalid day_count fails", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = mock_attrs(:post) |> Map.merge(%{communityId: community.id})
    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")

    Statistics.mock_throttle_attr(
      :last_publish_time,
      %User{id: user.id},
      minutes: -@throttle_interval
    )

    Statistics.mock_throttle_attr(
      :date_count,
      %User{id: user.id},
      count: @day_total
    )

    assert user_conn
           |> mutation_get_error?(@create_post_query, variables, ecode(:throttle_day))
  end

  test "user create multi content with valid day count success in next day", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = mock_attrs(:post) |> Map.merge(%{communityId: community.id})
    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")

    Statistics.mock_throttle_attr(
      :last_publish_time,
      %User{id: user.id},
      minutes: -@throttle_interval
    )

    Statistics.mock_throttle_attr(
      :date_count,
      %User{id: user.id},
      count: @day_total
    )

    assert user_conn
           |> mutation_get_error?(@create_post_query, variables, ecode(:throttle_day))

    Statistics.mock_throttle_attr(
      :publish_date,
      %User{id: user.id},
      days: -2
    )

    created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
    assert created |> Map.has_key?("id")
  end
end
