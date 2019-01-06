defmodule MastaniServerWeb.Resolvers.CMS do
  @moduledoc false

  import MastaniServer.CMS.Utils.Matcher
  import ShortMaps
  import Ecto.Query, warn: false

  alias Helper.ORM
  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS
  alias MastaniServer.CMS.{Post, Video, Repo, Job, Community, Category, Tag, Thread}

  # #######################
  # community ..
  # #######################
  def community(_root, %{id: id}, _info), do: Community |> ORM.find(id)

  def community(_root, %{title: title}, _info) do
    case Community |> ORM.find_by(title: title) do
      {:ok, community} -> {:ok, community}
      {:error, _} -> Community |> ORM.find_by(aka: title)
    end
  end

  def community(_root, %{raw: raw}, _info) do
    case Community |> ORM.find_by(raw: raw) do
      {:ok, community} -> {:ok, community}
      {:error, _} -> Community |> ORM.find_by(aka: raw)
    end
  end

  def community(_root, _args, _info), do: {:error, "please provide community id or title or raw"}
  def paged_communities(_root, ~m(filter)a, _info), do: Community |> ORM.find_all(filter)

  def create_community(_root, args, %{context: %{cur_user: user}}) do
    args = args |> Map.merge(%{user_id: user.id})
    Community |> ORM.create(args)
  end

  def update_community(_root, args, _info), do: Community |> ORM.find_update(args)

  def delete_community(_root, %{id: id}, _info), do: Community |> ORM.find_delete(id)

  # #######################
  # community thread (post, job), login user should be logged
  # #######################
  def post(_root, %{id: id}, %{context: %{cur_user: user}}) do
    CMS.read_content(:post, id, user)
  end

  def post(_root, %{id: id}, _info),
    do: Post |> ORM.read(id, inc: :views)

  def job(_root, %{id: id}, %{context: %{cur_user: user}}) do
    CMS.read_content(:job, id, user)
  end

  def job(_root, %{id: id}, _info), do: Job |> ORM.read(id, inc: :views)

  def video(_root, %{id: id}, %{context: %{cur_user: user}}) do
    CMS.read_content(:video, id, user)
  end

  def video(_root, %{id: id}, _info), do: Video |> ORM.read(id, inc: :views)

  def repo(_root, %{id: id}, %{context: %{cur_user: user}}) do
    CMS.read_content(:repo, id, user)
  end

  def repo(_root, %{id: id}, _info), do: Repo |> ORM.read(id, inc: :views)

  def wiki(_root, ~m(community)a, _info), do: CMS.get_wiki(%Community{raw: community})
  def cheatsheet(_root, ~m(community)a, _info), do: CMS.get_cheatsheet(%Community{raw: community})

  def paged_posts(_root, ~m(filter)a, %{context: %{cur_user: user}}) do
    Post |> CMS.paged_contents(filter, user)
  end

  def paged_posts(_root, ~m(filter)a, _info), do: Post |> CMS.paged_contents(filter)

  def paged_videos(_root, ~m(filter)a, %{context: %{cur_user: user}}) do
    Video |> CMS.paged_contents(filter, user)
  end

  def paged_videos(_root, ~m(filter)a, _info), do: Video |> CMS.paged_contents(filter)

  def paged_repos(_root, ~m(filter)a, %{context: %{cur_user: user}}) do
    Repo |> CMS.paged_contents(filter, user)
  end

  def paged_repos(_root, ~m(filter)a, _info), do: Repo |> CMS.paged_contents(filter)

  def paged_jobs(_root, ~m(filter)a, %{context: %{cur_user: user}}) do
    Job |> CMS.paged_contents(filter, user)
  end

  def paged_jobs(_root, ~m(filter)a, _info), do: Job |> CMS.paged_contents(filter)

  def create_content(_root, ~m(community_id thread)a = args, %{context: %{cur_user: user}}) do
    CMS.create_content(%Community{id: community_id}, thread, args, user)
  end

  def update_content(_root, %{passport_source: content, tags: _tags} = args, _info) do
    CMS.update_content(content, args)
  end

  def update_content(_root, %{passport_source: content} = args, _info) do
    ORM.update(content, args)
  end

  def delete_content(_root, %{passport_source: content}, _info), do: ORM.delete(content)

  # #######################
  # content flag ..
  # #######################
  def pin_content(_root, ~m(id community_id topic)a, _info) do
    CMS.pin_content(%CMS.Post{id: id}, %Community{id: community_id}, topic)
  end

  def pin_content(_root, ~m(id community_id thread)a, _info) do
    do_pin_content(id, community_id, thread)
  end

  def undo_pin_content(_root, ~m(id community_id topic)a, _info) do
    CMS.undo_pin_content(%CMS.Post{id: id}, %Community{id: community_id}, topic)
  end

  def undo_pin_content(_root, ~m(id community_id thread)a, _info) do
    do_undo_pin_content(id, community_id, thread)
  end

  def do_pin_content(id, community_id, :job),
    do: CMS.pin_content(%CMS.Job{id: id}, %Community{id: community_id})

  def do_pin_content(id, community_id, :video),
    do: CMS.pin_content(%CMS.Video{id: id}, %Community{id: community_id})

  def do_pin_content(id, community_id, :repo),
    do: CMS.pin_content(%CMS.Repo{id: id}, %Community{id: community_id})

  def do_undo_pin_content(id, community_id, :job) do
    CMS.undo_pin_content(%CMS.Job{id: id}, %Community{id: community_id})
  end

  def do_undo_pin_content(id, community_id, :video) do
    CMS.undo_pin_content(%CMS.Video{id: id}, %Community{id: community_id})
  end

  def do_undo_pin_content(id, community_id, :repo) do
    CMS.undo_pin_content(%CMS.Repo{id: id}, %Community{id: community_id})
  end

  def trash_content(_root, ~m(id thread community_id)a, _info),
    do: set_community_flags(community_id, thread, id, %{trash: true})

  def undo_trash_content(_root, ~m(id thread community_id)a, _info),
    do: set_community_flags(community_id, thread, id, %{trash: false})

  # TODO: report contents
  # def report_content(_root, ~m(id thread community_id)a, _info),
  # do: set_community_flags(community_id, thread, id, %{report: true})

  # def undo_report_content(_root, ~m(id thread community_id)a, _info),
  # do: set_community_flags(community_id, thread, id, %{report: false})

  defp set_community_flags(community_id, thread, id, flag) do
    with {:ok, content} <- match_action(thread, :self) do
      content.target
      |> struct(%{id: id})
      |> CMS.set_community_flags(community_id, flag)
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

  def favorited_category(root, ~m(thread)a, %{context: %{cur_user: user}}) do
    CMS.favorited_category(thread, root.id, user)
  end

  # #######################
  # category ..
  # #######################
  def paged_categories(_root, ~m(filter)a, _info), do: Category |> ORM.find_all(filter)

  def create_category(_root, ~m(title raw)a, %{context: %{cur_user: user}}) do
    CMS.create_category(%{title: title, raw: raw}, user)
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
  # geo infos ..
  # #######################
  def community_geo_info(_root, ~m(id)a, _info) do
    CMS.community_geo_info(%Community{id: id})
  end

  # #######################
  # tags ..
  # #######################
  def create_tag(_root, %{thread: thread, community_id: community_id} = args, %{
        context: %{cur_user: user}
      }) do
    CMS.create_tag(%Community{id: community_id}, thread, args, user)
  end

  def delete_tag(_root, %{id: id}, _info), do: Tag |> ORM.find_delete(id)

  def update_tag(_root, args, _info), do: CMS.update_tag(args)

  def set_tag(_root, ~m(community_id thread id tag_id)a, _info) do
    CMS.set_tag(%Community{id: community_id}, thread, %Tag{id: tag_id}, id)
  end

  def unset_tag(_root, ~m(id thread tag_id)a, _info) do
    CMS.unset_tag(thread, %Tag{id: tag_id}, id)
  end

  def get_tags(_root, %{community_id: community_id, all: true}, _info) do
    CMS.get_tags(%Community{id: community_id})
  end

  def get_tags(_root, %{community: community, all: true}, _info) do
    CMS.get_tags(%Community{raw: community})
  end

  def get_tags(_root, ~m(community_id thread topic)a, _info) do
    CMS.get_tags(%Community{id: community_id}, thread, topic)
  end

  def get_tags(_root, ~m(community thread topic)a, _info) do
    CMS.get_tags(%Community{raw: community}, thread, topic)
  end

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
  def subscribe_community(_root, ~m(community_id)a, %{context: ~m(cur_user remote_ip)a}) do
    CMS.subscribe_community(%Community{id: community_id}, cur_user, remote_ip)
  end

  def subscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.subscribe_community(%Community{id: community_id}, cur_user)
  end

  def unsubscribe_community(_root, ~m(community_id)a, %{context: %{cur_user: cur_user}}) do
    CMS.unsubscribe_community(%Community{id: community_id}, cur_user)
  end

  def community_subscribers(_root, ~m(id filter)a, _info) do
    CMS.community_members(:subscribers, %Community{id: id}, filter)
  end

  def community_subscribers(_root, ~m(community filter)a, _info) do
    CMS.community_members(:subscribers, %Community{raw: community}, filter)
  end

  def community_subscribers(_root, _args, _info), do: {:error, "invalid args"}

  def set_community(_root, ~m(thread id community_id)a, _info) do
    CMS.set_community(%Community{id: community_id}, thread, id)
  end

  def unset_community(_root, ~m(thread id community_id)a, _info) do
    CMS.unset_community(%Community{id: community_id}, thread, id)
  end

  # #######################
  # comemnts ..
  # #######################
  def paged_comments(_root, ~m(id thread filter)a, _info) do
    CMS.list_comments(thread, id, filter)
  end

  def paged_comments_participators(_root, ~m(id thread filter)a, _info) do
    CMS.list_comments_participators(thread, id, filter)
  end

  def paged_comments_participators(root, ~m(thread)a, _info) do
    CMS.list_comments_participators(thread, root.id, %{page: 1, size: 20})
  end

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

  # #######################
  # sync github content ..
  # #######################
  def sync_wiki(_root, ~m(community_id readme last_sync)a, %{context: %{cur_user: _user}}) do
    CMS.sync_github_content(%Community{id: community_id}, :wiki, ~m(readme last_sync)a)
  end

  def add_wiki_contributor(_root, ~m(id contributor)a, %{context: %{cur_user: _user}}) do
    CMS.add_contributor(%CMS.CommunityWiki{id: id}, contributor)
  end

  def sync_cheatsheet(_root, ~m(community_id readme last_sync)a, %{context: %{cur_user: _user}}) do
    CMS.sync_github_content(%Community{id: community_id}, :cheatsheet, ~m(readme last_sync)a)
  end

  def add_cheatsheet_contributor(_root, ~m(id contributor)a, %{context: %{cur_user: _user}}) do
    CMS.add_contributor(%CMS.CommunityCheatsheet{id: id}, contributor)
  end

  def search_items(_root, %{part: part, title: title}, _info) do
    CMS.search_items(part, %{title: title})
  end

  # ##############################################
  # counts just for manngers to use in admin site ..
  # ##############################################
  def threads_count(root, _, _) do
    CMS.count(%Community{id: root.id}, :threads)
  end

  def tags_count(root, _, _) do
    CMS.count(%Community{id: root.id}, :tags)
  end
end
