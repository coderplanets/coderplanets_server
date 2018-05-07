defmodule MastaniServer.Accounts do
  alias MastaniServer.Accounts.Delegate.AccountCURD

  # update user profile
  defdelegate update_profile(user_id, attrs), to: AccountCURD
  defdelegate github_signin(github_user), to: AccountCURD
  # default communities for unlog user
  defdelegate default_subscribed_communities(filter), to: AccountCURD
  # get user subscribed community
  defdelegate subscribed_communities(user_id, filter), to: AccountCURD
end
