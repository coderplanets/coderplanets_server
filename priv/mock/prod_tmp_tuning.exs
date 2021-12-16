# import GroupherServer.Support.Factory
import Ecto.Query, warn: false
import GroupherServer.Support.Factory

alias Helper.ORM
alias GroupherServer.{CMS, Repo, Accounts}
alias CMS.Model.{Community, Post, PostComment, Comment}
alias Accounts.Model.User

alias Helper.Converter
alias Converter.MdToEditor
alias Converter.Article
alias CMS.Delegate.{Document, Seeds}
alias Seeds.Prod.Turning

# {:ok, community} = ORM.find_by(Community, %{raw: "home"})
# {:ok, user} = ORM.find_by(User, %{login: "hello you"})

# post_attrs = mock_attrs(:meetup, %{community_id: community.id})

# {:ok, _meetup} = CMS.create_article(community, :post, post_attrs, user)
{:ok, _} = CMS.move_article(:post, 242, 105)

# ---
# XXX 社区上 Threads 和 Tags

# Seeds.Prod.Turning.seed_home()
# Seeds.Prod.Turning.seed_one_community(:feedback, :feedback)
# Seeds.Prod.Turning.seed_one_community(:elixir, :pl)
# ---

# -- 创建社区分类
# Turning.seed_categories()
# ---

# ---
# 给所有文章设置 active_at 和 archived_at
# {:ok, all_posts} = ORM.find_all(Post, %{page: 1, size: 200})

# all_posts.entries
# |> Enum.each(fn post ->
#   IO.inspect(post.updated_at, label: "updated_at")
#   ORM.update(post, %{active_at: post.inserted_at, archived_at: post.inserted_at})
# end)

# ---

# 给
# ----
# 迁移一篇帖子的评论
# post_id = 1

# {:ok, post} = ORM.find(Post, post_id, preload: :author)

# query = PostComment |> where([c], c.post_id == ^post.id)
# {:ok, post_comments} = ORM.find_all(query, %{page: 1, size: 100})

# post_comments.entries
# # |> Enum.take(1)
# |> Enum.each(fn comment ->
#   comment = Repo.preload(comment, :author)
#   body = MdToEditor.parse(comment.body)

#   {:ok, body_map} =
#     %{"blocks" => body, "time" => 10, "version" => "2.x"}
#     |> Jason.encode()

#   IO.inspect(body_map, label: "comment")
#   IO.inspect(comment.inserted_at, label: "inserted_at")
#   IO.inspect(comment.updated_at, label: "updated_at")
#   IO.inspect(post.author.user_id, label: "article author id")

#   original_inserted_at = comment.inserted_at
#   original_updated_at = comment.updated_at

#   {:ok, comment} = CMS.create_comment(:post, post.id, body_map, comment.author)

#   {:ok, _} =
#     ORM.update(comment, %{
#       inserted_at: original_inserted_at,
#       updated_at: original_updated_at,
#       is_archived: true,
#       archived_at: original_inserted_at,
#       is_article_author: comment.author_id == post.author.user_id
#     })
# end)

# ----
# 迁移所有帖子的评论
# {:ok, all_posts} = ORM.find_all(Post, %{page: 1, size: 200})

# all_posts.entries
# |> Enum.each(fn post ->
#   post = Repo.preload(post, :author)

#   query = PostComment |> where([c], c.post_id == ^post.id)
#   {:ok, post_comments} = ORM.find_all(query, %{page: 1, size: 100})

#   post_comments.entries
#   |> Enum.each(fn comment ->
#     comment = Repo.preload(comment, :author)
#     body = MdToEditor.parse(comment.body)

#     {:ok, body_map} =
#       %{"blocks" => body, "time" => 10, "version" => "2.x"}
#       |> Jason.encode()

#     IO.inspect(body_map, label: "comment")
#     # IO.inspect(comment.author, label: "author")
#     IO.inspect(comment.inserted_at, label: "inserted_at")
#     IO.inspect(comment.updated_at, label: "updated_at")
#     IO.inspect(post.author.user_id, label: "article author id")

#     original_inserted_at = comment.inserted_at
#     original_updated_at = comment.updated_at

#     {:ok, comment} = CMS.create_comment(:post, post.id, body_map, comment.author)

#     {:ok, _} =
#       ORM.update(comment, %{
#         inserted_at: original_inserted_at,
#         updated_at: original_updated_at,
#         is_archived: true,
#         archived_at: original_inserted_at,
#         is_article_author: comment.author_id == post.author.user_id
#       })
#   end)
# end)

# -----

# -----
# 转一篇文章到 Editor 格式
# {:ok, post} = ORM.find(Post, "141", preload: :author)

# body = MdToEditor.parse(post.body)
# IO.inspect(body, label: "body --")

# {:ok, body_map} =
#   %{"blocks" => body, "time" => 10, "version" => "2.x"}
#   |> Jason.encode()
#   |> IO.inspect(label: "encode")

# {:ok, _} = Document.create(post, %{body: body_map})
# {:ok, _} = Accounts.update_published_states(post.author.user_id, :post)

# ---------

# 转所有文章到 Editor 格式
# {:ok, all_posts} = ORM.find_all(Post, %{page: 1, size: 200})

# all_posts.entries
# |> Enum.each(fn post ->
#   body = MdToEditor.parse(post.body)

#   {:ok, body_map} =
#     %{"blocks" => body, "time" => 10, "version" => "2.x"}
#     |> Jason.encode()

#   {:ok, _} = Document.create(post, %{body: body_map})
#   post = Repo.preload(post, :author)
#   {:ok, _} = Accounts.update_published_states(post.author.user_id, :post)
# end)

# -----

# alias CMS.Delegate.Seeds
# Seeds.Prod.Turning.seed_home_tags()

# markdown to editor-json

# 设置某一个志愿者
# {:ok, home_community} = ORM.find_by(Community, %{raw: "home"})
# {:ok, me} = ORM.find_by(User, %{login: "mydearxym"})
# {:ok, _community} = CMS.set_editor(home_community, "volunteer", me)

# 批量设置志愿者
# {:ok, me} = ORM.find_by(User, %{login: "mydearxym"})
# {:ok, all_community} = ORM.find_all(Community, %{page: 1, size: 120})

# all_community.entries
# |> Enum.each(fn community ->
#   CMS.set_editor(community, "volunteer", me)
# end)

# 批量更新社区订阅者，内容数
# {:ok, all_community} = ORM.find_all(Community, %{page: 1, size: 120})

# all_community.entries
# |> Enum.each(fn community ->
#   # CMS.update_community_count_field(community, bot.id, :subscribers_count, :inc)
#   CMS.update_community_count_field(community, :post)
# end)
