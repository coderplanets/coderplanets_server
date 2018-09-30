defmodule MastaniServer.CMS do
  @moduledoc """
  this module defined basic method to handle [CMS] content [CURD] ..
  [CMS]: post, job, ...
  [CURD]: create, update, delete ...
  """
  alias MastaniServer.CMS.Delegate.{
    ArticleCURD,
    ArticleOperation,
    ArticleReaction,
    CommentCURD,
    CommunitySync,
    CommentReaction,
    CommunityCURD,
    CommunityOperation,
    PassportCURD
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
  # >> tag
  defdelegate create_tag(thread, attrs, user), to: CommunityCURD
  defdelegate update_tag(attrs), to: CommunityCURD
  defdelegate get_tags(community, thread), to: CommunityCURD
  defdelegate get_tags(filter), to: CommunityCURD
  # >> wiki & cheatsheet (sync with github)
  defdelegate sync_content(community, thread, attrs), to: CommunitySync
  defdelegate add_contributor(wiki, attrs), to: CommunitySync

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

  # ArticleCURD
  defdelegate paged_contents(queryable, filter), to: ArticleCURD
  defdelegate create_content(community, thread, attrs, user), to: ArticleCURD
  defdelegate reaction_users(thread, react, id, filters), to: ArticleCURD

  # ArticleReaction
  defdelegate reaction(thread, react, content_id, user), to: ArticleReaction
  defdelegate undo_reaction(thread, react, content_id, user), to: ArticleReaction

  # ArticleOperation
  # >> set flag on article, like: pin / unpin article
  defdelegate set_community_flags(queryable, community_id, attrs), to: ArticleOperation

  # >> tag: set / unset
  defdelegate set_tag(community, thread, tag, content_id), to: ArticleOperation
  defdelegate unset_tag(thread, tag, content_id), to: ArticleOperation
  # >> community: set / unset
  defdelegate set_community(community, thread, content_id), to: ArticleOperation
  defdelegate unset_community(community, thread, content_id), to: ArticleOperation

  # Comment CURD
  defdelegate create_comment(thread, content_id, body, user), to: CommentCURD
  defdelegate delete_comment(thread, content_id), to: CommentCURD
  defdelegate list_comments(thread, content_id, filters), to: CommentCURD
  defdelegate list_replies(thread, comment, user), to: CommentCURD
  defdelegate reply_comment(thread, comment, body, user), to: CommentCURD

  # Comment Reaction
  # >> like / undo like
  defdelegate like_comment(thread, comment, user), to: CommentReaction
  defdelegate undo_like_comment(thread, comment, user), to: CommentReaction
  # >> dislike / undo dislike
  defdelegate dislike_comment(thread, comment, user), to: CommentReaction
  defdelegate undo_dislike_comment(thread, comment, user), to: CommentReaction

  # Passport CURD
  defdelegate stamp_passport(rules, user), to: PassportCURD
  defdelegate erase_passport(rules, user), to: PassportCURD
  defdelegate get_passport(user), to: PassportCURD
  defdelegate list_passports(community, key), to: PassportCURD
  defdelegate delete_passport(user), to: PassportCURD
end
