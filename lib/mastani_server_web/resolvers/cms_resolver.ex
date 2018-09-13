defmodule MastaniServerWeb.Resolvers.CMS do
  @moduledoc false

  import MastaniServer.CMS.Utils.Matcher
  import ShortMaps
  import Ecto.Query, warn: false

  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS
  alias MastaniServer.CMS.{Post, Video, Repo, Job, Community, Category, Tag, Thread}
  alias Helper.ORM

  # #######################
  # community ..
  # #######################
  def community(_root, %{id: id}, _info), do: Community |> ORM.find(id)
  def community(_root, %{title: title}, _info), do: Community |> ORM.find_by(title: title)
  def community(_root, %{raw: raw}, _info), do: Community |> ORM.find_by(raw: raw)

  def community(_root, _args, _info), do: {:error, "please provide community id or title or raw"}
  def paged_communities(_root, ~m(filter)a, _info), do: Community |> ORM.find_all(filter)

  def create_community(_root, args, %{context: %{cur_user: user}}) do
    args = args |> Map.merge(%{user_id: user.id})
    Community |> ORM.create(args)
  end

  def update_community(_root, args, _info), do: Community |> ORM.find_update(args)

  def delete_community(_root, %{id: id}, _info), do: Community |> ORM.find_delete(id)

  # #######################
  # community thread (post, job)
  # #######################
  def post(_root, %{id: id}, _info), do: Post |> ORM.read(id, inc: :views)
  def video(_root, %{id: id}, _info), do: Video |> ORM.read(id, inc: :views)
  def repo(_root, %{id: id}, _info), do: Repo |> ORM.read(id, inc: :views)
  def job(_root, %{id: id}, _info), do: Job |> ORM.read(id, inc: :views)

  def paged_posts(_root, ~m(filter)a, _info), do: Post |> CMS.paged_contents(filter)
  def paged_videos(_root, ~m(filter)a, _info), do: Video |> CMS.paged_contents(filter)
  def paged_repos(_root, ~m(filter)a, _info), do: Repo |> CMS.paged_contents(filter)
  def paged_jobs(_root, ~m(filter)a, _info), do: Job |> ORM.find_all(filter)

  def create_content(_root, ~m(community_id thread)a = args, %{context: %{cur_user: user}}) do
    CMS.create_content(%Community{id: community_id}, thread, args, user)
  end

  def update_content(_root, %{passport_source: content} = args, _info),
    do: ORM.update(content, args)

  def delete_content(_root, %{passport_source: content}, _info), do: ORM.delete(content)

  # #######################
  # content flag ..
  # #######################
  def pin_content(_root, ~m(id type community_id)a, %{context: %{cur_user: _user}}) do
    with {:ok, content} <- match_action(type, :self) do
      content.target
      |> struct(%{id: id})
      |> CMS.set_community_flags(community_id, %{pin: true})
    end
  end

  def undo_pin_content(_root, ~m(id type community_id)a, %{context: %{cur_user: _user}}) do
    with {:ok, content} <- match_action(type, :self) do
      content.target
      |> struct(%{id: id})
      |> CMS.set_community_flags(community_id, %{pin: false})
    end
  end

  def trash_content(_root, ~m(id type community_id)a, %{context: %{cur_user: _user}}) do
    with {:ok, content} <- match_action(type, :self) do
      content.target
      |> struct(%{id: id})
      |> CMS.set_community_flags(community_id, %{trash: true})
    end
  end

  def undo_trash_content(_root, ~m(id type community_id)a, %{context: %{cur_user: _user}}) do
    with {:ok, content} <- match_action(type, :self) do
      content.target
      |> struct(%{id: id})
      |> CMS.set_community_flags(community_id, %{trash: false})
    end
  end

  # #######################
  # thread reaction ..
  # #######################
  def reaction(_root, ~m(id thread action)a, %{context: %{cur_user: user}}) do
    CMS.reaction(thread, action, id, user)
  end

  def undo_reaction(_root, ~m(id thread action)a, %{context: %{cur_user: user}}) do
    CMS.undo_reaction(thread, action, id, user)
  end

  def reaction_users(_root, ~m(id action thread filter)a, _info) do
    CMS.reaction_users(thread, action, id, filter)
  end

  # #######################
  # category ..
  # #######################
  def paged_categories(_root, ~m(filter)a, _info), do: Category |> ORM.find_all(filter)

  def create_category(_root, ~m(title raw)a, %{context: %{cur_user: user}}) do
    CMS.create_category(%Category{title: title, raw: raw}, user)
  end

  def delete_category(_root, %{id: id}, _info), do: Category |> ORM.find_delete(id)

  def update_category(_root, ~m(id title)a, %{context: %{cur_user: _}}) do
    CMS.update_category(~m(%Category id title)a)
  end

  def set_category(_root, ~m(community_id category_id)a, %{context: %{cur_user: _}}) do
    CMS.set_category(%Community{id: community_id}, %Category{id: category_id})
  end

  def unset_category(_root, ~m(community_id category_id)a, %{context: %{cur_user: _}}) do
    CMS.unset_category(%Community{id: community_id}, %Category{id: category_id})
  end

  # #######################
  # thread ..
  # #######################
  def paged_threads(_root, ~m(filter)a, _info), do: Thread |> ORM.find_all(filter)

  def create_thread(_root, ~m(title raw index)a, _info),
    do: CMS.create_thread(~m(title raw index)a)

  def set_thread(_root, ~m(community_id thread_id)a, _info) do
    CMS.set_thread(%Community{id: community_id}, %Thread{id: thread_id})
  end

  def unset_thread(_root, ~m(community_id thread_id)a, _info) do
    CMS.unset_thread(%Community{id: community_id}, %Thread{id: thread_id})
  end

  # #######################
  # editors ..
  # #######################
  def set_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.set_editor(%Community{id: community_id}, title, %User{id: user_id})
  end

  def unset_editor(_root, ~m(community_id user_id)a, _) do
    CMS.unset_editor(%Community{id: community_id}, %User{id: user_id})
  end

  def update_editor(_root, ~m(community_id user_id title)a, _) do
    CMS.update_editor(%Community{id: community_id}, title, %User{id: user_id})
  end

  def community_editors(_root, ~m(id filter)a, _info) do
    CMS.community_members(:editors, %Community{id: id}, filter)
  end

  # #######################
  # tags ..
  # #######################
  def create_tag(_root, args, %{context: %{cur_user: user}}) do
    CMS.create_tag(args.thread, args, user)
  end

  def delete_tag(_root, %{id: id}, _info), do: Tag |> ORM.find_delete(id)

  def update_tag(_root, args, _info), do: CMS.update_tag(args)

  def set_tag(_root, ~m(community_id thread id tag_id)a, _info) do
    CMS.set_tag(%Community{id: community_id}, thread, %Tag{id: tag_id}, id)
  end

  def unset_tag(_root, ~m(id thread tag_id)a, _info),
    do: CMS.unset_tag(thread, %Tag{id: tag_id}, id)

  def get_tags(_root, ~m(community_id thread)a, _info) do
    CMS.get_tags(%Community{id: community_id}, thread)
  end

  def get_tags(_root, ~m(community thread)a, _info) do
    CMS.get_tags(%Community{raw: community}, thread)
  end

  def get_tags(_root, %{thread: _thread}, _info) do
    {:error, "community_id or community is needed"}
  end

  def get_tags(_root, ~m(filter)a, _info), do: CMS.get_tags(filter)

  # #######################
  # community subscribe ..
  # #######################
  def subscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.subscribe_community(%Community{id: community_id}, cur_user)
  end

  def unsubscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.unsubscribe_community(%Community{id: community_id}, cur_user)
  end

  def community_subscribers(_root, ~m(id filter)a, _info) do
    CMS.community_members(:subscribers, %Community{id: id}, filter)
  end

  def set_community(_root, ~m(thread id community_id)a, _info) do
    CMS.set_community(%Community{id: community_id}, thread, id)
  end

  def unset_community(_root, ~m(thread id community_id)a, _info) do
    CMS.unset_community(%Community{id: community_id}, thread, id)
  end

  # #######################
  # comemnts ..
  # #######################
  def paged_comments(_root, ~m(id thread filter)a, _info),
    do: CMS.list_comments(thread, id, filter)

  def create_comment(_root, ~m(thread id body)a, %{context: %{cur_user: user}}) do
    CMS.create_comment(thread, id, body, user)
  end

  def delete_comment(_root, ~m(thread id)a, _info) do
    CMS.delete_comment(thread, id)
  end

  def reply_comment(_root, ~m(thread id body)a, %{context: %{cur_user: user}}) do
    CMS.reply_comment(thread, id, body, user)
  end

  def like_comment(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.like_comment(thread, id, user)
  end

  def undo_like_comment(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.undo_like_comment(thread, id, user)
  end

  def dislike_comment(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.dislike_comment(thread, id, user)
  end

  def undo_dislike_comment(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.undo_dislike_comment(thread, id, user)
  end

  def stamp_passport(_root, ~m(user_id rules)a, %{context: %{cur_user: _user}}) do
    CMS.stamp_passport(rules, %User{id: user_id})
  end
end
