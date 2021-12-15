defmodule GroupherServerWeb.Resolvers.CMS do
  @moduledoc false

  import ShortMaps
  import Ecto.Query, warn: false

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.{Community, Category, Thread, CommunityWiki, CommunityCheatsheet}

  alias Helper.ORM

  # #######################
  # community ..
  # #######################
  def community(_root, %{raw: raw}, %{context: %{cur_user: user}}) do
    CMS.read_community(raw, user)
  end

  def community(_root, %{raw: raw}, _info) do
    CMS.read_community(raw)
  end

  def paged_communities(_root, ~m(filter)a, %{context: %{cur_user: user}}) do
    CMS.paged_communities(filter, user)
  end

  def paged_communities(_root, ~m(filter)a, _info) do
    CMS.paged_communities(filter)
  end

  def create_community(_root, args, %{context: %{cur_user: user}}) do
    args = args |> Map.merge(%{user_id: user.id})
    CMS.create_community(args)
  end

  def update_community(_root, args, _info) do
    CMS.update_community(args.id, args)
  end

  def delete_community(_root, %{id: id}, _info), do: Community |> ORM.find_delete!(id)

  def apply_community(_root, args, %{context: %{cur_user: user}}) do
    args = args |> Map.merge(%{user_id: user.id})
    CMS.apply_community(args)
  end

  def approve_community_apply(_root, %{id: id}, _) do
    CMS.approve_community_apply(id)
  end

  def deny_community_apply(_root, %{id: id}, _) do
    CMS.deny_community_apply(id)
  end

  def is_community_exist?(_root, %{raw: raw}, _) do
    CMS.is_community_exist?(raw)
  end

  def has_pending_community_apply?(_root, _, %{context: %{cur_user: user}}) do
    CMS.has_pending_community_apply?(user)
  end

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

  def paged_reports(_root, ~m(filter)a, _) do
    CMS.paged_reports(filter)
  end

  # TODO: login only
  def blog_rss_info(_root, ~m(rss)a, _) do
    CMS.blog_rss_info(rss)
  end

  def update_rss_author(_root, attrs, _) do
    rss = Map.get(attrs, :rss)
    CMS.update_rss_author(rss, attrs)
  end

  def wiki(_root, ~m(community)a, _info), do: CMS.get_wiki(%Community{raw: community})
  def cheatsheet(_root, ~m(community)a, _info), do: CMS.get_cheatsheet(%Community{raw: community})

  def create_blog(_root, ~m(community_id)a = args, %{context: %{cur_user: user}}) do
    CMS.create_blog(%Community{id: community_id}, args, user)
  end

  def create_works(_root, args, %{context: %{cur_user: user}}) do
    CMS.create_works(args, user)
  end

  def update_works(_root, %{passport_source: works} = args, _info) do
    CMS.update_works(works, args)
  end

  def create_article(_root, ~m(community_id thread)a = args, %{context: %{cur_user: user}}) do
    CMS.create_article(%Community{id: community_id}, thread, args, user)
  end

  def update_article(_root, %{passport_source: article} = args, _info) do
    CMS.update_article(article, args)
  end

  def delete_article(_root, %{passport_source: article}, _info) do
    CMS.delete_article(article)
  end

  # #######################
  # article actions
  # #######################
  def pin_article(_root, ~m(id community_id thread)a, _info) do
    CMS.pin_article(thread, id, community_id)
  end

  def undo_pin_article(_root, ~m(id community_id thread)a, _info) do
    CMS.undo_pin_article(thread, id, community_id)
  end

  def mark_delete_article(_root, ~m(id thread)a, _info) do
    CMS.mark_delete_article(thread, id)
  end

  def undo_mark_delete_article(_root, ~m(id thread)a, _info) do
    CMS.undo_mark_delete_article(thread, id)
  end

  def report_article(_root, ~m(thread id reason attr)a, %{context: %{cur_user: user}}) do
    CMS.report_article(thread, id, reason, attr, user)
  end

  def undo_report_article(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.undo_report_article(thread, id, user)
  end

  def paged_citing_contents(_root, ~m(content id filter)a, _info) do
    CMS.paged_citing_contents(content, id, filter)
  end

  # #######################
  # thread reaction ..
  # #######################
  def lock_article_comments(_root, ~m(id thread)a, _info),
    do: CMS.lock_article_comments(thread, id)

  def undo_lock_article_comments(_root, ~m(id thread)a, _info) do
    CMS.undo_lock_article_comments(thread, id)
  end

  def sink_article(_root, ~m(id thread)a, _info), do: CMS.sink_article(thread, id)
  def undo_sink_article(_root, ~m(id thread)a, _info), do: CMS.undo_sink_article(thread, id)

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

  def emotion_to_article(_root, ~m(id thread emotion)a, %{context: %{cur_user: user}}) do
    CMS.emotion_to_article(thread, id, emotion, user)
  end

  def undo_emotion_to_article(_root, ~m(id thread emotion)a, %{context: %{cur_user: user}}) do
    CMS.undo_emotion_to_article(thread, id, emotion, user)
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

  def paged_community_editors(_root, ~m(id filter)a, _info) do
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
  def create_article_tag(_root, %{thread: thread, community_id: community_id} = args, %{
        context: %{cur_user: user}
      }) do
    CMS.create_article_tag(%Community{id: community_id}, thread, args, user)
  end

  def update_article_tag(_root, %{id: id} = args, _info) do
    CMS.update_article_tag(id, args)
  end

  def delete_article_tag(_root, %{id: id}, _info) do
    CMS.delete_article_tag(id)
  end

  def set_article_tag(_root, ~m(id thread article_tag_id)a, _info) do
    CMS.set_article_tag(thread, id, article_tag_id)
  end

  def unset_article_tag(_root, ~m(id thread article_tag_id)a, _info) do
    CMS.unset_article_tag(thread, id, article_tag_id)
  end

  def paged_article_tags(_root, %{filter: filter}, _info) do
    CMS.paged_article_tags(filter)
  end

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

  def paged_community_subscribers(_root, ~m(id filter)a, %{context: %{cur_user: cur_user}}) do
    CMS.community_members(:subscribers, %Community{id: id}, filter, cur_user)
  end

  def paged_community_subscribers(_root, ~m(id filter)a, _info) do
    CMS.community_members(:subscribers, %Community{id: id}, filter)
  end

  def paged_community_subscribers(_root, ~m(community filter)a, %{context: %{cur_user: cur_user}}) do
    CMS.community_members(:subscribers, %Community{raw: community}, filter, cur_user)
  end

  def paged_community_subscribers(_root, ~m(community filter)a, _info) do
    CMS.community_members(:subscribers, %Community{raw: community}, filter)
  end

  def paged_community_subscribers(_root, _args, _info), do: {:error, "invalid args"}

  def mirror_article(_root, ~m(thread id community_id)a, _info) do
    CMS.mirror_article(thread, id, community_id)
  end

  def unmirror_article(_root, ~m(thread id community_id)a, _info) do
    CMS.unmirror_article(thread, id, community_id)
  end

  def move_article(_root, ~m(thread id community_id article_tags)a, _info) do
    CMS.move_article(thread, id, community_id, article_tags)
  end

  def mirror_to_home(_root, ~m(thread id article_tags)a, _info) do
    CMS.mirror_to_home(thread, id, article_tags)
  end

  def move_to_blackhole(_root, ~m(thread id article_tags)a, _info) do
    CMS.move_to_blackhole(thread, id, article_tags)
  end

  # #######################
  # comemnts ..
  # #######################
  def comments_state(_root, ~m(thread id)a, %{context: %{cur_user: user}}) do
    CMS.comments_state(thread, id, user)
  end

  def comments_state(_root, ~m(thread id)a, _) do
    CMS.comments_state(thread, id)
  end

  def one_comment(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.one_comment(id, user)
  end

  def one_comment(_root, ~m(id)a, _) do
    CMS.one_comment(id)
  end

  def paged_comments(_root, ~m(id thread filter mode)a, %{context: %{cur_user: user}}) do
    case mode do
      :replies -> CMS.paged_comments(thread, id, filter, :replies, user)
      :timeline -> CMS.paged_comments(thread, id, filter, :timeline, user)
    end
  end

  def paged_comments(_root, ~m(id thread filter mode)a, _info) do
    case mode do
      :replies -> CMS.paged_comments(thread, id, filter, :replies)
      :timeline -> CMS.paged_comments(thread, id, filter, :timeline)
    end
  end

  def paged_comments_participants(_root, ~m(id thread filter)a, _info) do
    CMS.paged_comments_participants(thread, id, filter)
  end

  def create_comment(_root, ~m(thread id body)a, %{context: %{cur_user: user}}) do
    CMS.create_comment(thread, id, body, user)
  end

  def update_comment(_root, ~m(body passport_source)a, _info) do
    comment = passport_source
    CMS.update_comment(comment, body)
  end

  def delete_comment(_root, ~m(passport_source)a, _info) do
    comment = passport_source
    CMS.delete_comment(comment)
  end

  def reply_comment(_root, ~m(id body)a, %{context: %{cur_user: user}}) do
    CMS.reply_comment(id, body, user)
  end

  def upvote_comment(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.upvote_comment(id, user)
  end

  def undo_upvote_comment(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.undo_upvote_comment(id, user)
  end

  def emotion_to_comment(_root, ~m(id emotion)a, %{context: %{cur_user: user}}) do
    CMS.emotion_to_comment(id, emotion, user)
  end

  def undo_emotion_to_comment(_root, ~m(id emotion)a, %{context: %{cur_user: user}}) do
    CMS.undo_emotion_to_comment(id, emotion, user)
  end

  def mark_comment_solution(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.mark_comment_solution(id, user)
  end

  def undo_mark_comment_solution(_root, ~m(id)a, %{context: %{cur_user: user}}) do
    CMS.undo_mark_comment_solution(id, user)
  end

  def pin_comment(_root, ~m(id)a, _info), do: CMS.pin_comment(id)
  def undo_pin_comment(_root, ~m(id)a, _info), do: CMS.undo_pin_comment(id)

  ############
  ############
  ############

  def paged_comment_replies(_root, ~m(id filter)a, %{context: %{cur_user: user}}) do
    CMS.paged_comment_replies(id, filter, user)
  end

  def paged_comment_replies(_root, ~m(id filter)a, _info) do
    CMS.paged_comment_replies(id, filter)
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
    CMS.add_contributor(%CommunityWiki{id: id}, contributor)
  end

  def sync_cheatsheet(_root, ~m(community_id readme last_sync)a, %{context: %{cur_user: _user}}) do
    CMS.sync_github_content(%Community{id: community_id}, :cheatsheet, ~m(readme last_sync)a)
  end

  def add_cheatsheet_contributor(_root, ~m(id contributor)a, %{context: %{cur_user: _user}}) do
    CMS.add_contributor(%CommunityCheatsheet{id: id}, contributor)
  end

  def search_communities(_root, %{title: title, category: category}, %{context: %{cur_user: user}}) do
    CMS.search_communities(title, category, user)
  end

  def search_communities(_root, %{title: title, category: category}, _info) do
    CMS.search_communities(title, category)
  end

  def search_communities(_root, %{title: title}, %{context: %{cur_user: user}}) do
    CMS.search_communities(title, user)
  end

  def search_communities(_root, %{title: title}, _info) do
    CMS.search_communities(title)
  end

  def search_articles(_root, %{thread: thread, title: title}, _info) do
    CMS.search_articles(thread, %{title: title})
  end

  # ##############################################
  # counts just for manngers to use in admin site ..
  # ##############################################
  def threads_count(root, _, _) do
    CMS.count(%Community{id: root.id}, :threads)
  end

  def article_tags_count(root, _, _) do
    CMS.count(%Community{id: root.id}, :article_tags)
  end
end
