defmodule GroupherServer.Test.Statistics.PublishThrottle do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Statistics}
  alias Statistics.Model.PublishThrottle

  setup do
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(user_conn guest_conn community)a}
  end

  test "user first create content should add fresh throttle record.", ~m(community)a do
    {:ok, user} = db_insert(:user)
    post_attrs = mock_attrs(:post, %{community_id: community.id})
    {:ok, _post} = CMS.create_article(community, :post, post_attrs, user)

    {:ok, pt_record} = PublishThrottle |> ORM.find_by(user_id: user.id)

    assert pt_record.date_count == 1
    assert pt_record.hour_count == 1
  end

  test "user create 2 content should update throttle record.", ~m(community)a do
    {:ok, user} = db_insert(:user)
    post_attrs = mock_attrs(:post, %{community_id: community.id})
    post_attrs2 = mock_attrs(:post, %{community_id: community.id})
    {:ok, _post} = CMS.create_article(community, :post, post_attrs, user)
    {:ok, _post} = CMS.create_article(community, :post, post_attrs2, user)

    {:ok, pt_record} = PublishThrottle |> ORM.find_by(user_id: user.id)

    assert pt_record.date_count == 2
    assert pt_record.hour_count == 2
  end
end
