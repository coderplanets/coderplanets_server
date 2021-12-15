defmodule GroupherServer.Accounts do
  @moduledoc false

  alias GroupherServer.Accounts.Delegate.{
    Achievements,
    Customization,
    Fans,
    CollectFolder,
    Publish,
    Mailbox,
    Profile,
    UpvotedArticles,
    Search,
    Utils
  }

  # profile
  defdelegate read_user(user), to: Profile
  defdelegate read_user(login, user), to: Profile
  defdelegate paged_users(filter), to: Profile
  defdelegate paged_users(filter, user), to: Profile

  defdelegate update_profile(user, attrs), to: Profile
  defdelegate update_geo(user, remote_ip), to: Profile
  defdelegate update_subscribe_state(user), to: Profile
  defdelegate github_signin(github_user), to: Profile
  defdelegate default_subscribed_communities(filter), to: Profile
  defdelegate subscribed_communities(user, filter), to: Profile

  # collect folder
  defdelegate paged_collect_folders(user_id, filter), to: CollectFolder
  defdelegate paged_collect_folders(user_id, filter, owner), to: CollectFolder
  defdelegate paged_collect_folder_articles(folder_id, filter, user), to: CollectFolder
  defdelegate paged_collect_folder_articles(folder_id, filter), to: CollectFolder

  defdelegate create_collect_folder(attrs, user), to: CollectFolder
  defdelegate update_collect_folder(id, attrs), to: CollectFolder
  defdelegate delete_collect_folder(id), to: CollectFolder
  defdelegate add_to_collect(thread, article_id, folder_id, user), to: CollectFolder
  defdelegate remove_from_collect(thread, article_id, folder_id, user), to: CollectFolder

  # achievement
  defdelegate achieve(user, operation, key), to: Achievements
  defdelegate paged_editable_communities(user, filter), to: Achievements
  defdelegate downgrade_achievement(user, action, count), to: Achievements
  # defdelegate paged_editable_communities(filter), to: Achievements

  # publish
  defdelegate paged_published_articles(user, thread, filter), to: Publish
  defdelegate paged_published_comments(user, thread, filter), to: Publish
  defdelegate paged_published_comments(user, thread), to: Publish
  defdelegate update_published_states(user, thread), to: Publish

  # fans
  defdelegate follow(user, follower), to: Fans
  defdelegate undo_follow(user, follower), to: Fans
  defdelegate paged_followers(user, filter), to: Fans
  defdelegate paged_followers(user, filter, cur_user), to: Fans
  defdelegate paged_followings(user, filter), to: Fans
  defdelegate paged_followings(user, filter, cur_user), to: Fans

  # upvoted articles
  defdelegate paged_upvoted_articles(user_id, filter), to: UpvotedArticles

  defdelegate mailbox_status(user), to: Mailbox
  defdelegate update_mailbox_status(user_id), to: Mailbox
  defdelegate mark_read(type, ids, user_id), to: Mailbox
  defdelegate mark_read_all(tyoe, user_id), to: Mailbox

  defdelegate paged_mailbox_messages(type, user, filter), to: Mailbox

  # customization
  defdelegate get_customization(user), to: Customization
  defdelegate set_customization(user, key, value), to: Customization
  defdelegate set_customization(user, options), to: Customization
  defdelegate upgrade_by_plan(user, plan), to: Customization

  defdelegate search_users(args), to: Search

  defdelegate get_userid_and_cache(login), to: Utils
end
