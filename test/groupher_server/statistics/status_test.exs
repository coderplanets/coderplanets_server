defmodule GroupherServer.Test.Statistics.Status do
  use GroupherServer.TestTools

  # alias Helper.ORM
  alias GroupherServer.Statistics
  alias Helper.Cache

  @communities_count 10
  # @posts_count 11

  setup do
    {:ok, _} = db_insert_multi(:community, @communities_count)

    :ok
  end

  test "can get basic online state" do
    {:ok, state} = Statistics.online_status()
    assert state == %{realtime_visitors: 1}
    Cache.put(:online_status, :realtime_visitors, 10)

    {:ok, state} = Statistics.online_status()
    assert state == %{realtime_visitors: 10}
  end

  test "can get basic count info of the whole site" do
    {:ok, counts} = Statistics.count_status()

    assert counts.communities_count == @communities_count
    # assert counts.posts_count == @posts_count
    # TODO: more
  end
end
