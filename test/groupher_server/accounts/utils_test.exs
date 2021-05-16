defmodule GroupherServer.Test.Accounts.Utils do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.Accounts
  alias Helper.Cache

  @cache_pool :user_login

  describe "[get userid]" do
    test "get_userid_and_cache should work" do
      {:ok, user} = db_insert(:user)

      {:ok, user_id} = Accounts.get_userid_and_cache(user.login)
      assert user.id == user_id

      assert {:ok, user_id} = Cache.get(@cache_pool, user.login)
      assert user_id == user.id
    end
  end
end
