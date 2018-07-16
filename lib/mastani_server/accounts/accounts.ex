defmodule MastaniServer.Accounts do
  @moduledoc false

  alias MastaniServer.Accounts.Delegate.{Profile, ReactedContents, Mails, Billing, Customization}

  # update user profile
  defdelegate update_profile(user_id, attrs), to: Profile
  defdelegate github_signin(github_user), to: Profile
  # default communities for unlog user
  defdelegate default_subscribed_communities(filter), to: Profile
  # get user subscribed community
  defdelegate subscribed_communities(user_id, filter), to: Profile

  # reacted contents
  defdelegate reacted_contents(thread, react, filter, user), to: ReactedContents

  # mentions
  defdelegate fetch_mentions(user, filter), to: Mails

  # notifications
  defdelegate fetch_notifications(user, filter), to: Mails
  defdelegate fetch_sys_notifications(user, filter), to: Mails

  # common message
  defdelegate mailbox_status(user), to: Mails
  defdelegate mark_mail_read_all(user, opt), to: Mails
  defdelegate mark_mail_read(mail, user), to: Mails

  # purchase
  defdelegate purchase_service(user, key, value), to: Billing
  defdelegate purchase_service(user, key), to: Billing
  defdelegate has_purchased?(user, key), to: Billing

  # customization
  defdelegate add_custom_setting(user, key, value), to: Customization
  defdelegate add_custom_setting(user, key), to: Customization
end
