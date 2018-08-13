defmodule MastaniServerWeb.Resolvers.Accounts do
  @moduledoc """
  accounts resolvers
  """
  import ShortMaps

  alias Helper.{Certification, ORM}
  alias MastaniServer.{Accounts, CMS}

  alias Accounts.{MentionMail, NotificationMail, SysNotificationMail, User}

  def user(_root, %{id: id}, _info), do: User |> ORM.find(id)
  def users(_root, ~m(filter)a, _info), do: User |> ORM.find_all(filter)

  def login_state(_root, _args, %{context: %{cur_user: cur_user}}),
    do: {:ok, %{is_login: true, user: cur_user}}

  def login_state(_root, _args, _info), do: {:ok, %{is_login: false}}

  def account(_root, _args, %{context: %{cur_user: cur_user}}) do
    User |> ORM.find(cur_user.id)
  end

  def update_profile(_root, %{profile: profile}, %{context: %{cur_user: cur_user}}) do
    Accounts.update_profile(%User{id: cur_user.id}, profile)
  end

  def github_signin(_root, %{github_user: github_user}, _info) do
    Accounts.github_signin(github_user)
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

  # for check other users query
  def favorited_posts(_root, ~m(user_id filter)a, _info) do
    Accounts.reacted_contents(:post, :favorite, filter, %User{id: user_id})
  end

  def favorited_posts(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.reacted_contents(:post, :favorite, filter, cur_user)
  end

  def favorited_jobs(_root, ~m(user_id filter)a, _info) do
    Accounts.reacted_contents(:job, :favorite, filter, %User{id: user_id})
  end

  def favorited_jobs(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.reacted_contents(:job, :favorite, filter, cur_user)
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
  def subscribed_communities(_root, %{filter: filter}, %{cur_user: cur_user}) do
    Accounts.subscribed_communities(%User{id: cur_user.id}, filter)
  end

  #
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
    case CMS.get_passport(%User{id: root.id}) do
      {:ok, passport} ->
        {:ok, Jason.encode!(passport)}

      {:error, _} ->
        {:ok, nil}
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
