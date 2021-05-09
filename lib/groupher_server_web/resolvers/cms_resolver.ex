defmodule GroupherServerWeb.Resolvers.CMS do
  @moduledoc false

  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps
  import Ecto.Query, warn: false

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.User
  alias CMS.{Community, Category, Tag, Thread}

  alias Helper.ORM

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

  def delete_community(_root, %{id: id}, _info), do: Community |> ORM.find_delete!(id)

  # #######################
  # community thread (post, job), login user should be logged
  # #######################
  def read_article(_root, %{thread: thread, id: id}, %{context: %{cur_user: user}}) do
    CMS.read_article(thread, id, user)
  end

  def read_article(_root, %{thread: thread, id: id}, _info) do
    CMS.read_article(thread, id)
  end

  def paged_articles(_root, ~m(thread filter)a, %{context: %{cur_user: user}}) do
    CMS.paged_articles(thread, filter, user)
  end

  def paged_articles(_root, ~m(thread filter)a, _info) do
    CMS.paged_articles(thread, filter)
  end

  def wiki(_root, ~m(community)a, _info), do: CMS.get_wiki(%Community{raw: community})
  def cheatsheet(_root, ~m(community)a, _info), do: CMS.get_cheatsheet(%Community{raw: community})

  def create_content(_root, ~m(community_id thread)a = args, %{context: %{cur_user: user}}) do
    CMS.create_content(%Community{id: community_id}, thread, args, user)
  end

  def update_content(_root, %{passport_source: content} = args, _info) do
    CMS.update_content(content, args)
  end

  def delete_content(_root, %{passport_source: content}, _info), do: ORM.delete(content)

  # #######################
  # content flag ..
  # #######################
  def pin_article(_root, ~m(id community_id thread)a, _info) do
    CMS.pin_article(thread, id, community_id)
  end

  def undo_pin_article(_root, ~m(id community_id thread)a, _info) do
    CMS.undo_pin_article(thread, id, community_id)
  end

  def trash_content(_root, ~m(id thread community_id)a, _info) do
    set_community_flags(community_id, thread, id, %{trash: true})
  end

  def undo_trash_content(_root, ~m(id thread community_id)a, _info) do
    set_community_flags(community_id, thread, id, %{trash: false})
  end

  # TODO: report contents
  # def report_content(_root, ~m(id thread community_id)a, _info),
  # do: set_community_flags(community_id, thread, id, %{report: true})

  # def undo_report_content(_root, ~m(id thread community_id)a, _info),
  # do: set_community_flags(community_id, thread, id, %{report: false})

  defp set_community_flags(community_id, thread, id, flag) do
    with {:ok, content} <- match_action(thread, :self) do
      queryable = content.target |> struct(%{id: id})

      CMS.set_community_flags(community_id, queryable, flag)
    end
  end

  # #######################
  # thread reaction ..
  # #######################
  def upvote_article(_root, ~m(id thread)a, %{context: %{cur_user: user}}) do
    CMS.upvote_article(thread, id, user)
  end

  def undo_upvote_article(_root, ~m(id thread)a, %{context: %{cur_user: user}}) do
    CMS.undo_upvote_article(thread, id, user)
  end

  def upvoted_users(_root, ~m(id thread filter)a, _info) do
    CMS.upvoted_users(thread, id, filter)
  end

  def collected_users(_root, ~m(id thread filter)a, _info) do
    CMS.collected_users(thread, id, filter)
  end

  # #######################
  # category ..
  # #######################
  def paged_categories(_root, ~m(filter)a, _info), do: Category |> ORM.find_all(filter)

  def create_category(_root, ~m(title raw)a, %{context: %{cur_user: user}}) do
    CMS.create_category(%{title: title, raw: raw}, user)
  end

  def delete_category(_root, %{id: id}, _info), do: Category |> ORM.find_delete!(id)

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

  def delete_tag(_root, %{id: id}, _info), do: Tag |> ORM.find_delete!(id)

  def update_tag(_root, args, _info), do: CMS.update_tag(args)

  def set_tag(_root, ~m(thread id tag_id)a, _info) do
    CMS.set_tag(thread, %Tag{id: tag_id}, id)
  end

  def set_refined_tag(_root, ~m(community_id thread id)a, _info) do
    CMS.set_refined_tag(%Community{id: community_id}, thread, id)
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

  def get_tags(_root, ~m(community_id thread)a, _info) do
    CMS.get_tags(%Community{id: community_id}, thread)
  end

  def get_tags(_root, ~m(community thread)a, _info) do
    CMS.get_tags(%Community{raw: community}, thread)
  end

  def get_tags(_root, ~m(community_id thread)a, _info) do
    CMS.get_tags(%Community{id: community_id}, thread)
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

  def unsubscribe_community(_root, ~m(community_id)a, %{context: ~m(cur_user remote_ip)a}) do
    CMS.unsubscribe_community(%Community{id: community_id}, cur_user, remote_ip)
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
  def paged_article_comments(_root, ~m(id thread filter mode)a, %{context: %{cur_user: user}}) do
    case mode do
      :replies -> CMS.list_article_comments(thread, id, filter, :replies, user)
      :timeline -> CMS.list_article_comments(thread, id, filter, :timeline, user)
    end
  end

  def paged_article_comments(_root, ~m(id thread filter mode)a, _info) do
    case mode do
      :replies -> CMS.list_article_comments(thread, id, filter, :replies)
      :timeline -> CMS.list_article_comments(thread, id, filter, :timeline)
    end
  end

  def paged_article_comments_participators(_root, ~m(id thread filter)a, _info) do
    CMS.list_article_comments_participators(thread, id, filter)
  end

  def create_article_comment(_root, ~m(thread id content)a, %{context: %{cur_user: user}}) do
    CMS.create_article_comment(thread, id, content, user)
  end

  def update_article_comment(_root, ~m(content passport_source)a, _info) do
    comment = passport_source
    CMS.update_article_comment(comment, content)
  end

  def delete_article_comment(_root, ~m(passport_source)a, _info) do
    comment = passport_source
    CMS.delete_article_comment(comment)
  end

  def reply_article_comment(_root, ~m(id content)a, %{context: %{cur_user: user}}) do
    CMS.reply_article_comment(id, content, user)
  end

  def emotion_to_comment(_root, ~m(id emotion)a, %{context: %{cur_user: user}}) do
    CMS.emotion_to_comment(id, emotion, user)
  end

  def undo_emotion_to_comment(_root, ~m(id emotion)a, %{context: %{cur_user: user}}) do
    CMS.undo_emotion_to_comment(id, emotion, user)
  end

  ############
  ############
  ############

  def paged_comment_replies(_root, ~m(id filter)a, %{context: %{cur_user: user}}) do
    CMS.list_comment_replies(id, filter, user)
  end

  def paged_comment_replies(_root, ~m(id filter)a, _info) do
    CMS.list_comment_replies(id, filter)
  end

  def paged_comments(_root, ~m(id thread filter)a, _info) do
    CMS.list_comments(thread, id, filter)
  end

  def paged_comments_participators(_root, ~m(id thread filter)a, _info) do
    CMS.list_comments_participators(thread, id, filter)
  end

  def paged_comments_participators(root, ~m(thread)a, _info) do
    CMS.list_comments_participators(thread, root.id, %{page: 1, size: 20})
  end

  def create_comment(_root, ~m(thread id)a = args, %{context: %{cur_user: user}}) do
    CMS.create_comment(thread, id, args, user)
  end

  def update_comment(_root, ~m(thread id)a = args, %{context: %{cur_user: user}}) do
    CMS.update_comment(thread, id, args, user)
  end

  def delete_comment(_root, ~m(thread id)a, _info) do
    CMS.delete_comment(thread, id)
  end

  def reply_comment(_root, ~m(thread id)a = args, %{context: %{cur_user: user}}) do
    CMS.reply_comment(thread, id, args, user)
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
