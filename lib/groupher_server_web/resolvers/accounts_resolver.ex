defmodule GroupherServerWeb.Resolvers.Accounts do
  @moduledoc """
  accounts resolvers
  """
  import ShortMaps
  import Helper.ErrorCode

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias Helper.Certification

  def user(_root, %{login: login}, %{context: %{cur_user: cur_user}}) do
    Accounts.read_user(login, cur_user)
  end

  def user(_root, %{login: login}, _info), do: Accounts.read_user(login)
  def user(_root, _args, _info), do: raise_error(:account_login, "need user login name")

  def paged_users(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.paged_users(filter, cur_user)
  end

  def paged_users(_root, ~m(filter)a, _info), do: Accounts.paged_users(filter)

  def session_state(_root, _args, %{context: %{cur_user: cur_user, remote_ip: remote_ip}}) do
    # 1. store remote_ip
    # 2. subscribe home community if not
    Accounts.update_geo(cur_user, remote_ip)
    CMS.subscribe_default_community_ifnot(cur_user, remote_ip)
    {:ok, %{is_valid: true, user: cur_user}}
  end

  def session_state(_root, _args, %{context: %{cur_user: cur_user}}) do
    CMS.subscribe_default_community_ifnot(cur_user)
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

    profile =
      if Map.has_key?(args, :social),
        do: Map.merge(profile, %{social: args.social}),
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

  def set_customization(_root, args, %{context: %{cur_user: cur_user}}) do
    customization = add_c11n_communities_index_ifneed(args)
    Accounts.set_customization(cur_user, customization)
  end

  def set_customization(_root, _args, _info) do
    {:error, [message: "need login", code: ecode(:account_login)]}
  end

  def follow(_root, ~m(login)a, %{context: %{cur_user: cur_user}}) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.follow(cur_user, %User{id: user_id})
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def undo_follow(_root, ~m(login)a, %{context: %{cur_user: cur_user}}) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.undo_follow(cur_user, %User{id: user_id})
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def paged_followers(_root, ~m(login filter)a, %{context: %{cur_user: cur_user}}) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_followers(%User{id: user_id}, filter, cur_user)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def paged_followers(_root, ~m(login filter)a, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_followers(%User{id: user_id}, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def paged_followings(_root, ~m(login filter)a, %{context: %{cur_user: cur_user}}) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_followings(%User{id: user_id}, filter, cur_user)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def paged_followings(_root, ~m(login filter)a, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_followings(%User{id: user_id}, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def paged_upvoted_articles(_root, ~m(login filter)a, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_upvoted_articles(user_id, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def create_collect_folder(_root, attrs, %{context: %{cur_user: cur_user}}) do
    Accounts.create_collect_folder(attrs, cur_user)
  end

  def update_collect_folder(_root, %{id: id} = attrs, _) do
    Accounts.update_collect_folder(id, attrs)
  end

  def delete_collect_folder(_root, %{id: id}, _) do
    Accounts.delete_collect_folder(id)
  end

  def add_to_collect(_root, ~m(thread article_id folder_id)a, %{context: %{cur_user: cur_user}}) do
    Accounts.add_to_collect(thread, article_id, folder_id, cur_user)
  end

  def remove_from_collect(_root, ~m(thread article_id folder_id)a, %{
        context: %{cur_user: cur_user}
      }) do
    Accounts.remove_from_collect(thread, article_id, folder_id, cur_user)
  end

  def paged_collect_folders(_root, ~m(login filter)a, %{context: %{cur_user: cur_user}}) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_collect_folders(user_id, filter, cur_user)
    end
  end

  def paged_collect_folders(_root, ~m(login filter)a, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_collect_folders(user_id, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def paged_collected_articles(_root, ~m(folder_id filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.paged_collect_folder_articles(folder_id, filter, cur_user)
  end

  def paged_collected_articles(_root, ~m(folder_id filter)a, _info) do
    Accounts.paged_collect_folder_articles(folder_id, filter)
  end

  # published contents
  def paged_published_articles(_root, ~m(login filter thread)a, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_published_articles(%User{id: user_id}, thread, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def paged_published_articles(_root, ~m(filter thread)a, %{context: %{cur_user: cur_user}}) do
    Accounts.paged_published_articles(cur_user, thread, filter)
  end

  def paged_published_comments(_root, ~m(login filter thread)a, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_published_comments(%User{id: user_id}, thread, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def paged_published_comments(_root, ~m(login filter)a, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_published_comments(%User{id: user_id}, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  # paged communities which the user it's the editor
  def editable_communities(_root, ~m(login filter)a, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.paged_editable_communities(%User{id: user_id}, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
  end

  def editable_communities(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.paged_editable_communities(cur_user, filter)
  end

  # mailbox
  def mailbox_status(_root, _args, %{context: %{cur_user: cur_user}}) do
    Accounts.mailbox_status(cur_user)
  end

  def mark_read(_root, ~m(type ids)a, %{context: %{cur_user: cur_user}}) do
    Accounts.mark_read(type, ids, cur_user)
  end

  def mark_read_all(_root, ~m(type)a, %{context: %{cur_user: cur_user}}) do
    Accounts.mark_read_all(type, cur_user)
  end

  def paged_mailbox_mentions(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.paged_mailbox_messages(:mention, cur_user, filter)
  end

  def paged_mailbox_notifications(_root, ~m(filter)a, %{context: %{cur_user: cur_user}}) do
    Accounts.paged_mailbox_messages(:notification, cur_user, filter)
  end

  # mailbox end

  # for check other users subscribed_communities
  def subscribed_communities(_root, %{login: login, filter: filter}, _info) do
    with {:ok, user_id} <- Accounts.get_userid_and_cache(login) do
      Accounts.subscribed_communities(%User{id: user_id}, filter)
    else
      _ -> raise_error(:not_exsit, "#{login} not found")
    end
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

    {:ok, %{cms: cms_rules}}
  end

  # def create_user(_root, args, %{context: %{cur_user: %{root: true}}}) do
  # Accounts.create_user2(args)
  # end
  def search_users(_root, %{name: name}, _info) do
    Accounts.search_users(%{name: name})
  end

  defp add_c11n_communities_index_ifneed(~m(customization)a = args) do
    case Map.has_key?(args, :sidebar_communities_index) do
      true ->
        sidebar_communities_index =
          try do
            args
            |> Map.get(:sidebar_communities_index, [])
            |> Enum.map(fn %{community: c, index: i} -> {c, i} end)
            |> Map.new()
          rescue
            _ -> %{}
          end

        Map.merge(customization, %{sidebar_communities_index: sidebar_communities_index})

      false ->
        customization
    end
  end
end
