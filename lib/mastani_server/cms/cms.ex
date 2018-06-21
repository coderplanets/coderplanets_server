defmodule MastaniServer.CMS do
  @moduledoc """
  this module defined basic method to handle [CMS] content [CURD] ..
  [CMS]: post, job, ...
  [CURD]: create, update, delete ...
  """
  alias MastaniServer.CMS.Delegate.{
    ArticleOperation,
    ArticleCURD,
    ArticleReaction,
    CommentReaction,
    CommentCURD,
    CommunityCURD,
    PassportCURD,
    CommunityOperation
  }

  # do not pattern match in delegating func, do it on one delegating inside
  # see https://github.com/elixir-lang/elixir/issues/5306

  # Community CURD: editors, thread, tag
  # >> editor ..
  defdelegate update_editor(user_id, community_id, title), to: CommunityCURD
  # >> subscribers / editors
  defdelegate community_members(type, community_id, filters), to: CommunityCURD
  # >> category
  defdelegate create_category(category_attrs, user_id), to: CommunityCURD
  defdelegate update_category(category_attrs), to: CommunityCURD
  # >> thread
  defdelegate create_thread(attrs), to: CommunityCURD
  # >> tag
  defdelegate create_tag(thread, attrs, user_id), to: CommunityCURD
  defdelegate update_tag(attrs), to: CommunityCURD
  defdelegate get_tags(community_info, thread), to: CommunityCURD
  defdelegate get_tags(filter), to: CommunityCURD

  # CommunityOperation
  # >> category
  defdelegate set_category(community_id, category_id), to: CommunityOperation
  defdelegate unset_category(community_id, category_id), to: CommunityOperation
  # >> editor
  defdelegate set_editor(user, community, title), to: CommunityOperation
  defdelegate unset_editor(user_id, community_id), to: CommunityOperation
  # >> thread
  defdelegate set_thread(community, thread), to: CommunityOperation
  defdelegate unset_thread(community, thread), to: CommunityOperation
  # >> subscribe / unsubscribe
  defdelegate subscribe_community(user_id, community_id), to: CommunityOperation
  defdelegate unsubscribe_community(user_id, community_id), to: CommunityOperation

  # ArticleCURD
  defdelegate create_content(thread, author_id, attrs), to: ArticleCURD
  defdelegate reaction_users(thread, react, id, filters), to: ArticleCURD

  # ArticleReaction
  defdelegate reaction(thread, react, thread_id, user_id), to: ArticleReaction
  defdelegate undo_reaction(thread, react, thread_id, user_id), to: ArticleReaction

  # ArticleOperation
  # >> tag: set / unset
  defdelegate set_tag(thread, thread_id, community_title, tag_id), to: ArticleOperation
  defdelegate unset_tag(thread, thread_id, tag_id), to: ArticleOperation
  # >> community: set / unset
  defdelegate set_community(thread, thread_id, community_id), to: ArticleOperation
  defdelegate unset_community(thread, thread_id, community_id), to: ArticleOperation
  # >> reaction

  # Comment CURD
  defdelegate create_comment(thread, thread_id, user_id, body), to: CommentCURD
  defdelegate delete_comment(thread, thread_id), to: CommentCURD
  defdelegate list_comments(thread, thread_id, filters), to: CommentCURD
  defdelegate list_replies(thread, comment_id, user_id), to: CommentCURD
  defdelegate reply_comment(thread, comment_id, user_id, body), to: CommentCURD

  # Comment Reaction
  # >> like / undo like
  defdelegate like_comment(thread, comment_id, user_id), to: CommentReaction
  defdelegate undo_like_comment(thread, comment_id, user_id), to: CommentReaction
  # >> dislike / undo dislike
  defdelegate dislike_comment(thread, comment_id, user_id), to: CommentReaction
  defdelegate undo_dislike_comment(thread, comment_id, user_id), to: CommentReaction

  # Passport CURD
  defdelegate stamp_passport(user_id, rules), to: PassportCURD
  defdelegate erase_passport(user_id, rules), to: PassportCURD
  defdelegate get_passport(user_id), to: PassportCURD
  defdelegate list_passports(community, key), to: PassportCURD
  defdelegate delete_passport(user_id), to: PassportCURD
end
