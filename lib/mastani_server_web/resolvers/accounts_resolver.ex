defmodule MastaniServerWeb.Resolvers.Accounts do
  @moduledoc """
  accounts resolvers
  """
  import ShortMaps
  import Helper.ErrorCode

  alias Helper.{Certification, ORM, RadarSearch}
  alias MastaniServer.{Accounts, CMS}

  alias Accounts.{MentionMail, NotificationMail, SysNotificationMail, User}

  def user(_root, %{id: id}, _info), do: User |> ORM.read(id, inc: :views)

  def user(_root, _args, %{context: %{cur_user: cur_user}}),
    do: User |> ORM.read(cur_user.id, inc: :views)

  def user(_root, _args, _info) do
    {:error, [message: "need login", code: ecode(:account_login)]}
  end

  def users(_root, ~m(filter)a, _info), do: User |> ORM.find_all(filter)

  def session_state(_root, _args, %{context: %{cur_user: cur_user, remote_ip: remote_ip}}) do
    Accounts.update_geo(cur_user, remote_ip)
    {:ok, %{is_valid: true, user: cur_user}}
  end

  def session_state(_root, _args, %{context: %{cur_user: cur_user}}) do
    {:ok, %{is_valid: true, user: cur_user}}
  end

  def session_state(_root, _args, _info), do: {:ok, %{is_valid: false}}

  def update_profile(_root, args, %{context: %{cur_user: cur_user}}) do
    profile =
      if Map.has_key?(args, :education_backgrounds),
        do: Map.merge(args.profile, %{education_backgrounds: args.education_backgrounds}),
        else: args.profile

    profile =
      if Map.has_key?(args, :work_backgrounds),
        do: Map.merge(profile, %{work_backgrounds: args.work_backgrounds}),
        else: profile

    Accounts.update_profile(%User{id: cur_user.id}, profile)
  end

  def github_signin(_root, %{github_user: github_user}, _info) do
    Accounts.github_signin(github_user)
  end

  def get_customization(_root, _args, %{context: %{cur_user: cur_user}}) do
    Accounts.get_customization(cur_user)
  end

  # def set_customization(_root, ~m(user_id customization)a, %{context: %{cur_user: cur_user}}) do
  # Accounts.set_customization(%User{id: user_id}, customization)
  # end

  def set_customization(_root, ~m(customization)a, %{context: %{cur_user: cur_user}}) do
    Accounts.set_customization(cur_user, customization)
  end

  def set_customization(_root, _args, _info) do
    {:error, [message: "need login", code: ecode(:account_login)]}
  end

  def list_favorite_categories(_root, %{filter: filter}, %{context: %{cur_user: cur_user}}) do
    Accounts.list_favorite_categories(cur_user, %{private: true}, filter)
  end

  def list_favorite_categories(_root, %{user_id: user_id, filter: filter}, _info) do
    Accounts.list_favorite_categories(%User{id: user_id}, %{private: false}, filter)
  end

  def create_favorite_category(_root, attrs, %{context: %{cur_user: cur_user}}) do
    Accounts.create_favorite_category(cur_user, attrs)
  end

  def update_favorite_category(_root, %{id: _id} = args, %{context: %{cur_user: cur_user}}) do
    Accounts.update_favorite_category(cur_user, args)
  end

  def delete_favorite_category(_root, %{id: id}, %{context: %{cur_user: cur_user}}) do
    Accounts.delete_favorite_category(cur_user, id)
  end

  def set_favorites(_root, ~m(id thread category_id)a, %{context: %{cur_user: cur_user}}) do
    Accounts.set_favorites(cur_user, thread, id, category_id)
  end

  def unset_favorites(_root, ~m(id thread category_id)a, %{context: %{cur_user: cur_user}}) do
    Accounts.unset_favorites(cur_user, thread, id, category_id)
  end

  def follow(_root, ~m(user_id)a, %{context: %{cur_user: cur_user}}) do
    Accounts.follow(cur_user, %User{id: user_id})
  end

  def undo_follow(_root, ~m(user_id)a, %{context: %{cur_user: cur_user}}) do
    Accounts.undo_follow(cur_user, %User{id: user_id})
  end

  def paged_followers(_root, ~m(user_id filter)a, _info) do
    Accounts.fetch_followers(%User{id: user_id}, filter)
  end

  def paged_followers(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.fetch_followers(cur_user, filter)
  end

  def paged_followings(_root, ~m(user_id filter)a, _info) do
    Accounts.fetch_followings(%User{id: user_id}, filter)
  end

  def paged_followings(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.fetch_followings(cur_user, filter)
  end

  # get favorited contents
  def favorited_contents(_root, ~m(user_id category_id filter thread)a, _info) do
    Accounts.reacted_contents(thread, :favorite, category_id, filter, %User{id: user_id})
  end

  def favorited_contents(_root, ~m(user_id filter thread)a, _info) do
    Accounts.reacted_contents(thread, :favorite, filter, %User{id: user_id})
  end

  def favorited_contents(_root, ~m(filter thread)a, %{context: %{cur_user: cur_user}}) do
    Accounts.reacted_contents(thread, :favorite, filter, cur_user)
  end

  # gst stared contents
  def stared_contents(_root, ~m(user_id filter thread)a, _info) do
    Accounts.reacted_contents(thread, :star, filter, %User{id: user_id})
  end

  def stared_contents(_root, ~m(filter thread)a, %{context: %{cur_user: cur_user}}) do
    Accounts.reacted_contents(thread, :star, filter, cur_user)
  end

  # published contents
  def published_contents(_root, ~m(user_id filter thread)a, _info) do
    Accounts.published_contents(%User{id: user_id}, thread, filter)
  end

  def published_contents(_root, ~m(filter thread)a, %{context: %{cur_user: cur_user}}) do
    Accounts.published_contents(cur_user, thread, filter)
  end

  # published comments
  def published_comments(_root, ~m(user_id filter thread)a, _info) do
    Accounts.published_comments(%User{id: user_id}, thread, filter)
  end

  def published_comments(_root, ~m(filter thread)a, %{context: %{cur_user: cur_user}}) do
    Accounts.published_comments(cur_user, thread, filter)
  end

  # paged communities which the user it's the editor
  def editable_communities(_root, ~m(user_id filter)a, _info) do
    Accounts.list_editable_communities(%User{id: user_id}, filter)
  end

  def editable_communities(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.list_editable_communities(cur_user, filter)
  end

  def editable_communities(root, ~m(filter)a, _info) do
    Accounts.list_editable_communities(%User{id: root.id}, filter)
  end

  # TODO: refactor
  def get_mail_box_status(_root, _args, %{context: %{cur_user: cur_user}}) do
    Accounts.mailbox_status(cur_user)
  end

  # mentions
  def fetch_mentions(_root, %{filter: filter}, %{context: %{cur_user: cur_user}}) do
    Accounts.fetch_mentions(cur_user, filter)
  end

  def mark_mention_read(_root, %{id: id}, %{context: %{cur_user: cur_user}}) do
    Accounts.mark_mail_read(%MentionMail{id: id}, cur_user)
  end

  def mark_mention_read_all(_root, _args, %{context: %{cur_user: cur_user}}) do
    Accounts.mark_mail_read_all(cur_user, :mention)
  end

  # notification
  def fetch_notifications(_root, %{filter: filter}, %{context: %{cur_user: cur_user}}) do
    Accounts.fetch_notifications(cur_user, filter)
  end

  def fetch_sys_notifications(_root, %{filter: filter}, %{context: %{cur_user: cur_user}}) do
    Accounts.fetch_sys_notifications(cur_user, filter)
  end

  def mark_notification_read(_root, %{id: id}, %{context: %{cur_user: cur_user}}) do
    Accounts.mark_mail_read(%NotificationMail{id: id}, cur_user)
  end

  def mark_notification_read_all(_root, _args, %{context: %{cur_user: cur_user}}) do
    Accounts.mark_mail_read_all(cur_user, :notification)
  end

  def mark_sys_notification_read(_root, %{id: id}, %{context: %{cur_user: cur_user}}) do
    Accounts.mark_mail_read(%SysNotificationMail{id: id}, cur_user)
  end

  # for user self's
  def subscribed_communities(_root, %{filter: filter}, %{context: %{cur_user: cur_user}}) do
    Accounts.subscribed_communities(%User{id: cur_user.id}, filter)
  end

  def subscribed_communities(%{id: id}, %{filter: filter}, _info) do
    Accounts.subscribed_communities(%User{id: id}, filter)
  end

  def subscribed_communities(_root, %{user_id: "", filter: filter}, _info) do
    Accounts.default_subscribed_communities(filter)
  end

  # for check other users subscribed_communities
  def subscribed_communities(_root, %{user_id: user_id, filter: filter}, _info) do
    Accounts.subscribed_communities(%User{id: user_id}, filter)
  end

  def subscribed_communities(_root, %{filter: filter}, _info) do
    Accounts.default_subscribed_communities(filter)
  end

  def get_passport(root, _args, %{context: %{cur_user: _}}) do
    CMS.get_passport(%User{id: root.id})
  end

  def get_passport_string(root, _args, %{context: %{cur_user: _}}) do
    with {:ok, passport} <- CMS.get_passport(%User{id: root.id}) do
      {:ok, Jason.encode!(passport)}
    end
  end

  def get_all_rules(_root, _args, %{context: %{cur_user: _}}) do
    cms_rules = Certification.all_rules(:cms, :stringify)

    {:ok,
     %{
       cms: cms_rules
     }}
  end

  # def create_user(_root, args, %{context: %{cur_user: %{root: true}}}) do
  # Accounts.create_user2(args)
  # end
end
