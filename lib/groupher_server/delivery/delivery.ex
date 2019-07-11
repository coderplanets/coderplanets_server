defmodule GroupherServer.Delivery do
  @moduledoc """
  The Delivery context.
  """

  alias GroupherServer.Delivery
  alias Delivery.Delegate.{Mentions, Notifications, Utils}

  defdelegate mailbox_status(user), to: Utils

  # system_notifications
  defdelegate publish_system_notification(info), to: Notifications
  defdelegate fetch_sys_notifications(user, filter), to: Notifications

  # mentions
  defdelegate mention_others(from_user, to_user_ids, info), to: Mentions
  defdelegate mention_from_content(community, thread, content, args, user), to: Mentions
  defdelegate mention_from_comment(community, thread, content, comment, args, user), to: Mentions
  defdelegate mention_from_comment_reply(community, thread, comment, args, user), to: Mentions
  defdelegate fetch_mentions(user, filter), to: Mentions

  # notifications
  defdelegate notify_someone(from_user, to_user, info), to: Notifications
  defdelegate fetch_notifications(user, filter), to: Notifications

  defdelegate fetch_record(user), to: Utils
  defdelegate mark_read_all(user, opt), to: Utils
end
