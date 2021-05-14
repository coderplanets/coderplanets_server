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
    ArticleCommunity,
    ArticleEmotion,
    ArticleComment,
    ArticleCollect,
    ArticleUpvote,
    ArticleCommentAction,
    ArticleCommentEmotion,
    CommentCURD,
    CommunitySync,
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
  defdelegate read_article(thread, id), to: ArticleCURD
  defdelegate read_article(thread, id, user), to: ArticleCURD

  defdelegate paged_articles(queryable, filter), to: ArticleCURD
  defdelegate paged_articles(queryable, filter, user), to: ArticleCURD

  defdelegate create_article(community, thread, attrs, user), to: ArticleCURD
  defdelegate update_article(content, attrs), to: ArticleCURD

  defdelegate upvote_article(thread, article_id, user), to: ArticleUpvote
  defdelegate undo_upvote_article(thread, article_id, user), to: ArticleUpvote

  defdelegate upvoted_users(thread, article_id, filter), to: ArticleUpvote

  defdelegate collect_article(thread, article_id, user), to: ArticleCollect
  defdelegate collect_article_ifneed(thread, article_id, user), to: ArticleCollect

  defdelegate undo_collect_article(thread, article_id, user), to: ArticleCollect
  defdelegate undo_collect_article_ifneed(thread, article_id, user), to: ArticleCollect
  defdelegate collected_users(thread, article_id, filter), to: ArticleCollect

  defdelegate set_collect_folder(collect, folder), to: ArticleCollect
  defdelegate undo_set_collect_folder(collect, folder), to: ArticleCollect

  # ArticleCommunity
  # >> set flag on article, like: pin / unpin article
  defdelegate set_community_flags(community_info, queryable, attrs), to: ArticleCommunity
  defdelegate pin_article(thread, id, community_id), to: ArticleCommunity
  defdelegate undo_pin_article(thread, id, community_id), to: ArticleCommunity

  defdelegate lock_article_comment(content), to: ArticleCommunity

  # >> tag: set / unset
  defdelegate set_tag(thread, tag, content_id), to: ArticleCommunity
  defdelegate unset_tag(thread, tag, content_id), to: ArticleCommunity
  # >> community: set / unset
  defdelegate mirror_community(thread, article_id, community_id), to: ArticleCommunity
  defdelegate unmirror_community(thread, article_id, community_id), to: ArticleCommunity
  defdelegate move_article(thread, article_id, community_id), to: ArticleCommunity

  defdelegate emotion_to_article(thread, article_id, args, user), to: ArticleEmotion
  defdelegate undo_emotion_to_article(thread, article_id, args, user), to: ArticleEmotion

  # Comment CURD
  defdelegate paged_article_comments(thread, article_id, filters, mode), to: ArticleComment
  defdelegate paged_article_comments(thread, article_id, filters, mode, user), to: ArticleComment

  defdelegate paged_folded_article_comments(thread, article_id, filters), to: ArticleComment
  defdelegate paged_folded_article_comments(thread, article_id, filters, user), to: ArticleComment

  defdelegate paged_comment_replies(comment_id, filters), to: ArticleComment
  defdelegate paged_comment_replies(comment_id, filters, user), to: ArticleComment

  defdelegate paged_article_comments_participators(thread, content_id, filters),
    to: ArticleComment

  defdelegate create_article_comment(thread, article_id, args, user), to: ArticleComment
  defdelegate update_article_comment(comment, content), to: ArticleComment
  defdelegate delete_article_comment(comment), to: ArticleComment

  defdelegate upvote_article_comment(comment_id, user), to: ArticleCommentAction
  defdelegate undo_upvote_article_comment(comment_id, user), to: ArticleCommentAction
  defdelegate reply_article_comment(comment_id, args, user), to: ArticleCommentAction

  defdelegate pin_article_comment(comment_id), to: ArticleCommentAction
  defdelegate undo_pin_article_comment(comment_id), to: ArticleCommentAction

  defdelegate fold_article_comment(comment_id, user), to: ArticleCommentAction
  defdelegate unfold_article_comment(comment_id, user), to: ArticleCommentAction

  defdelegate emotion_to_comment(comment_id, args, user), to: ArticleCommentEmotion
  defdelegate undo_emotion_to_comment(comment_id, args, user), to: ArticleCommentEmotion
  ###################
  ###################
  ###################
  ###################
  defdelegate create_comment(thread, content_id, args, user), to: CommentCURD
  defdelegate update_comment(thread, id, args, user), to: CommentCURD
  defdelegate delete_comment(thread, content_id), to: CommentCURD
  defdelegate paged_replies(thread, comment, user), to: CommentCURD
  defdelegate reply_comment(thread, comment, args, user), to: CommentCURD

  defdelegate paged_comments(thread, content_id, filters), to: CommentCURD
  defdelegate paged_comments_participators(thread, content_id, filters), to: CommentCURD

  # TODO: move report to abuse report module
  defdelegate report_article(thread, article_id, reason, attr, user), to: AbuseReport
  defdelegate report_article_comment(comment_id, reason, attr, user), to: AbuseReport
  defdelegate report_account(account_id, reason, attr, user), to: AbuseReport
  defdelegate undo_report_account(account_id, user), to: AbuseReport
  defdelegate undo_report_article(thread, article_id, user), to: AbuseReport
  defdelegate paged_reports(filter), to: AbuseReport
  defdelegate undo_report_article_comment(comment_id, user), to: AbuseReport

  # Passport CURD
  defdelegate stamp_passport(rules, user), to: PassportCURD
  defdelegate erase_passport(rules, user), to: PassportCURD
  defdelegate get_passport(user), to: PassportCURD
  defdelegate paged_passports(community, key), to: PassportCURD
  defdelegate delete_passport(user), to: PassportCURD

  # search
  defdelegate search_items(part, args), to: Search

  # seeds
  defdelegate seed_communities(opt), to: Seeds
  defdelegate seed_set_category(communities, category), to: Seeds
  defdelegate seed_bot, to: Seeds
end
