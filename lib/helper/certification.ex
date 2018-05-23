defmodule Helper.Certification do
  @moduledoc """
  valid editors and passport details
  """
  def editor_titles(:cms) do
    ["chief editor", "post editor"]
  end

  def passport_rules(cms: "chief editor") do
    %{
      "post.tag.create" => true,
      "post.tag.edit" => true,
      "post.article.trash" => true
    }
  end

  def all_rules do
    [
      # 添加 editor
      # "cms->c?->editor.add"
      "editor.add",
      # 编辑 post 文章
      "post.edit",
      # 删除 post 文章
      "post.trash",
      "post.delete",
      # 帖子 版块 [添加] 标签
      "post.tag.add",
      "post.tag.edit",
      "post.tag.delete",
      "post.tag.trash",
      # 具体的 post/tag 惭怍
      "post.tag.set",
      "post.tag.unset",
      # 具体的 post/community 惭怍
      "post.community.set",
      "post.community.unset",
      # post 置顶操作
      "post.top.set",
      "post.top.unset"
    ]
  end
end

# 可以编辑某个社区 post 版块的文章, 支持 owner
# middleware(M.Passport, claim: "cms->c?->posts.article.edit")
# middleware(M.Passport, claim: "owner;cms->c?->posts.article.edit")

# 可以添加某个社区 posts 版块的 tag 标签, 同时可支持 owner
# middleware(M.Passport, claim: "cms->c?->posts.tag.add")
# middleware(M.Passport, claim: "cms->c?->posts.tag.edit")
# middleware(M.Passport, claim: "cms->c?->posts.tag.delete")
# middleware(M.Passport, claim: "cms->c?->posts.tag.trash")
# middleware(M.Passport, claim: "owner;cms->c?->posts.tag.delete")

# 可以给某个社区 posts 版块的 posts 设置标签(setTag), 同时可支持 owner?
# middleware(M.Passport, claim: "c?->posts.tag.set")

# 可以某个社区的 posts 版块置顶
# middleware(M.Passport, claim: "cms->c?->posts.setTop")

# 可以编辑某个社区所有版块的文章
# middleware(M.Passport, claim: "cms->c?->posts.articles.edit")
# middleware(M.Passport, claim: "cms->c?->job.articles.edit")
# ....全部显示声明....
# middleware(M.Passport, claim: "cms->c?->radar.articles.edit")

# 可以给某个社区的某个版块添加/删除管理员, 实际上就是在给其他成员分配上面的权限,同时该用户会被添加到相应的管理员中
# middleware(M.Passport, claim: "cms->c?->posts.managers.add")
# middleware(M.Passport, claim: "cms->c?->jobs.managers.add")
# middleware(M.Passport, claim: "cms->c?->videos.managers.add")
# middleware(M.Passport, claim: "cms->c?->videos.managers.delete")

# 可以给社区的版块设置审核后发布
# middleware(M.Passport, claim: "cms->c?->settings.posts.needReview")
# middleware(M.Passport, claim: "cms->c?->posts.reviewer") # 审核员 (一开始没必要加)

# 在某个社区的某个版块屏蔽某个用户
# middleware(M.Passport, claim: "cms->c?->viewer->block")

# 查看某个社区的总访问量
# middleware(M.Passport, claim: "statistics->c?->click")
# middleware(M.Passport, claim: "logs->c?->posts ...")

# defguard the_fuck(value) when String.contains?(value, "->?")
# classify the require of this gateway
