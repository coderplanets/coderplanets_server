defmodule MastaniServer.Test.Statistics.Status do
  use MastaniServer.TestTools

  # alias Helper.ORM
  alias MastaniServer.Statistics

  @communities_count 10
  # @posts_count 11

  setup do
    {:ok, _} = db_insert_multi(:community, @communities_count)
    # {:ok, _} = db_insert_multi(:post, @posts_count)

    :ok
  end

  test "can get basic count info of the whole site" do
    {:ok, counts} = Statistics.count_status()

    assert counts.communities_count == @communities_count
    # assert counts.posts_count == @posts_count
    # TODO: more
  end
end
