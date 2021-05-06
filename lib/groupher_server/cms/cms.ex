defmodule GroupherServer.CMS do
  @moduledoc """
  this module defined basic method to handle [CMS] content [CURD] ..
  [CMS]: post, job, ...
  [CURD]: create, update, delete ...
  """

  alias GroupherServer.CMS.Delegate

  alias Delegate.{
    AbuseReport,
    ArticleCURD,
    ArticleOperation,
    ArticleReaction,
    ArticleComment,
    CommentCURD,
    CommunitySync,
    CommentReaction,
    CommunityCURD,
    CommunityOperation,
    PassportCURD,
    Search,
    Seeds
  }

  # do not pattern match in delegating func, do it on one delegating inside
  # see https://github.com/elixir-lang/elixir/issues/5306

  # Community CURD: editors, thread, tag
  # >> editor ..
  defdelegate update_editor(user, community, title), to: CommunityCURD
  # >> geo info ..
  defdelegate community_geo_info(community), to: CommunityCURD
  # >> subscribers / editors
  defdelegate community_members(type, community, filters), to: CommunityCURD
  # >> category
  defdelegate create_category(category_attrs, user), to: CommunityCURD
  defdelegate update_category(category_attrs), to: CommunityCURD
  # >> thread
  defdelegate create_thread(attrs), to: CommunityCURD
  defdelegate count(community, part), to: CommunityCURD
  # >> tag
  defdelegate create_tag(community, thread, attrs, user), to: CommunityCURD
  defdelegate update_tag(attrs), to: CommunityCURD
  defdelegate get_tags(community, thread), to: CommunityCURD
  defdelegate get_tags(filter), to: CommunityCURD
  # >> wiki & cheatsheet (sync with github)
  defdelegate get_wiki(community), to: CommunitySync
  defdelegate get_cheatsheet(community), to: CommunitySync
  defdelegate sync_github_content(community, thread, attrs), to: CommunitySync
  defdelegate add_contributor(content, attrs), to: CommunitySync

  # CommunityOperation
  # >> category
  defdelegate set_category(community, category), to: CommunityOperation
  defdelegate unset_category(community, category), to: CommunityOperation
  # >> editor
  defdelegate set_editor(community, title, user), to: CommunityOperation
  defdelegate unset_editor(community, user), to: CommunityOperation
  # >> thread
  defdelegate set_thread(community, thread), to: CommunityOperation
  defdelegate unset_thread(community, thread), to: CommunityOperation
  # >> subscribe / unsubscribe
  defdelegate subscribe_community(community, user), to: CommunityOperation
  defdelegate subscribe_community(community, user, remote_ip), to: CommunityOperation
  defdelegate unsubscribe_community(community, user), to: CommunityOperation
  defdelegate unsubscribe_community(community, user, remote_ip), to: CommunityOperation

  defdelegate subscribe_default_community_ifnot(user, remote_ip), to: CommunityOperation
  defdelegate subscribe_default_community_ifnot(user), to: CommunityOperation

  # ArticleCURD
  defdelegate read_content(thread, id, user), to: ArticleCURD
  defdelegate paged_contents(queryable, filter, user), to: ArticleCURD
  defdelegate paged_contents(queryable, filter), to: ArticleCURD
  defdelegate create_content(community, thread, attrs, user), to: ArticleCURD
  defdelegate update_content(content, attrs), to: ArticleCURD

  # ArticleReaction
  defdelegate upvote_article(thread, article_id, user), to: ArticleReaction
  defdelegate undo_upvote_article(thread, article_id, user), to: ArticleReaction

  defdelegate upvoted_users(thread, article_id, filter), to: ArticleReaction

  defdelegate collect_article(thread, article_id, user), to: ArticleReaction
  defdelegate collect_article_ifneed(thread, article_id, user), to: ArticleReaction

  defdelegate undo_collect_article(thread, article_id, user), to: ArticleReaction
  defdelegate undo_collect_article_ifneed(thread, article_id, user), to: ArticleReaction
  defdelegate collected_users(thread, article_id, filter), to: ArticleReaction

  defdelegate set_collect_folder(collect, folder), to: ArticleReaction
  defdelegate undo_set_collect_folder(collect, folder), to: ArticleReaction

  # ArticleOperation
  # >> set flag on article, like: pin / unpin article
  defdelegate set_community_flags(community_info, queryable, attrs), to: ArticleOperation
  defdelegate pin_article(thread, id, community_id), to: ArticleOperation
  defdelegate undo_pin_article(thread, id, community_id), to: ArticleOperation

  defdelegate lock_article_comment(content), to: ArticleOperation

  # >> tag: set / unset
  defdelegate set_tag(thread, tag, content_id), to: ArticleOperation
  defdelegate unset_tag(thread, tag, content_id), to: ArticleOperation
  # >> community: set / unset
  defdelegate set_community(community, thread, content_id), to: ArticleOperation
  defdelegate unset_community(community, thread, content_id), to: ArticleOperation

  # Comment CURD
  defdelegate list_article_comments(thread, article_id, filters, mode), to: ArticleComment
  defdelegate list_article_comments(thread, article_id, filters, mode, user), to: ArticleComment

  defdelegate list_folded_article_comments(thread, article_id, filters), to: ArticleComment
  defdelegate list_folded_article_comments(thread, article_id, filters, user), to: ArticleComment
  defdelegate list_reported_article_comments(thread, article_id, filters), to: ArticleComment

  defdelegate list_reported_article_comments(thread, article_id, filters, user),
    to: ArticleComment

  defdelegate list_comment_replies(comment_id, filters), to: ArticleComment
  defdelegate list_comment_replies(comment_id, filters, user), to: ArticleComment
  defdelegate list_article_comments_participators(thread, content_id, filters), to: ArticleComment

  defdelegate create_article_comment(thread, article_id, args, user), to: ArticleComment
  defdelegate upvote_article_comment(comment_id, user), to: ArticleComment
  defdelegate undo_upvote_article_comment(comment_id, user), to: ArticleComment
  defdelegate delete_article_comment(comment_id, user), to: ArticleComment
  defdelegate reply_article_comment(comment_id, args, user), to: ArticleComment

  defdelegate pin_article_comment(comment_id), to: ArticleComment
  defdelegate undo_pin_article_comment(comment_id), to: ArticleComment

  defdelegate make_emotion(comment_id, args, user), to: ArticleComment
  defdelegate fold_article_comment(comment_id, user), to: ArticleComment
  defdelegate unfold_article_comment(comment_id, user), to: ArticleComment
  defdelegate report_article_comment(comment_id, user), to: ArticleComment
  defdelegate unreport_article_comment(comment_id, user), to: ArticleComment

  defdelegate create_comment(thread, content_id, args, user), to: CommentCURD
  defdelegate update_comment(thread, id, args, user), to: CommentCURD
  defdelegate delete_comment(thread, content_id), to: CommentCURD
  defdelegate list_replies(thread, comment, user), to: CommentCURD
  defdelegate reply_comment(thread, comment, args, user), to: CommentCURD

  defdelegate list_comments(thread, content_id, filters), to: CommentCURD
  defdelegate list_comments_participators(thread, content_id, filters), to: CommentCURD

  # report
  defdelegate create_report(type, content_id, args, user), to: AbuseReport

  # Passport CURD
  defdelegate stamp_passport(rules, user), to: PassportCURD
  defdelegate erase_passport(rules, user), to: PassportCURD
  defdelegate get_passport(user), to: PassportCURD
  defdelegate list_passports(community, key), to: PassportCURD
  defdelegate delete_passport(user), to: PassportCURD

  # search
  defdelegate search_items(part, args), to: Search

  # seeds
  defdelegate seed_communities(opt), to: Seeds
  defdelegate seed_set_category(communities, category), to: Seeds
  defdelegate seed_bot, to: Seeds
end
