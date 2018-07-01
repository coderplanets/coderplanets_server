defmodule MastaniServer.Accounts do
  alias MastaniServer.Accounts.Delegate.{AccountCURD, AccountMails}

  # update user profile
  defdelegate update_profile(user_id, attrs), to: AccountCURD
  defdelegate github_signin(github_user), to: AccountCURD
  # default communities for unlog user
  defdelegate default_subscribed_communities(filter), to: AccountCURD
  # get user subscribed community
  defdelegate subscribed_communities(user_id, filter), to: AccountCURD

  defdelegate fetch_mentions(user, filter), to: AccountMails
  defdelegate mark_mail_read(mail, user), to: AccountMails
  defdelegate mark_mail_read_all(user, opt), to: AccountMails
end
