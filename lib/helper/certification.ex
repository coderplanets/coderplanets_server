defmodule Helper.Certification do
  @moduledoc """
  valid editors and passport details
  """
  def editor_titles(:cms) do
    ["chief editor", "post editor"]
  end

  def passport_rules(cms: "chief editor") do
    %{
      "post.article_tag.create" => true,
      "post.article_tag.edit" => true,
      "post.mark_delete" => true
    }
  end

  # a |> Enum.map(fn(x) -> {x, false} end) |> Map.new
  # %{
  # cms: %{
  # system: ..,
  # community: ...,
  # },
  # statistics: %{
  # ....
  # },
  # otherMoudle: %{

  # }
  # }

  @doc """
  基础权限，社区权限
  """
  def all_rules(:cms) do
    %{
      general: [
        "root",
        "system_accountant",
        "system_notification.publish",
        "stamp_passport",
        # community
        "editor.set",
        "editor.unset",
        "editor.update",
        "community.create",
        "community.update",
        "community.delete",
        "category.create",
        "category.delete",
        "category.update",
        "category.set",
        "category.unset",
        "thread.create",
        "post.community.mirror",
        "post.community.move",
        "post.community.unmirror",
        "job.community.mirror",
        "job.community.move",
        "job.community.unmirror",
        # flag on content
        # pin/undo_pin
        "post.pin",
        "post.undo_pin",
        "job.pin",
        "job.undo_pin",
        "repo.pin",
        "repo.undo_pin",
        # sink/undo_sink
        "post.sink",
        "post.undo_sink",
        "job.sink",
        "job.undo_sink",
        "repo.sink",
        "repo.undo_sink",
        #
        "post.mark_delete",
        "post.undo_mark_delete",
        "job.mark_delete",
        "job.undo_mark_delete",
        "repo.mark_delete",
        "repo.undo_mark_delete"
      ],
      community: [
        # thread
        "thread.set",
        "thread.unset",
        "post.edit",
        "post.mark_delete",
        "post.delete",
        "job.edit",
        "job.mark_delete",
        "job.delete",
        # post article_tag
        "post.article_tag.create",
        "post.article_tag.update",
        "post.article_tag.delete",
        "post.article_tag.set",
        "post.article_tag.unset",
        # post flag
        "post.pin",
        "post.undo_pin",
        "post.mark_delete",
        "post.undo_mark_delete",
        # job article_tag
        "job.article_tag.create",
        "job.article_tag.update",
        "job.article_tag.delete",
        "job.article_tag.set",
        "job.article_tag.unset",
        # job flag
        "job.pin",
        "job.undo_pin",
        "job.mark_delete",
        "job.undo_mark_delete",
        # repo article_tag
        "repo.article_tag.create",
        "repo.article_tag.update",
        "repo.article_tag.delete",
        "repo.article_tag.set",
        "repo.article_tag.unset",
        # repo flag
        "repo.pin",
        "repo.undo_pin",
        "repo.mark_delete",
        "repo.undo_mark_delete"
      ]
    }
  end

  def all_rules(:cms, :stringify) do
    rules = all_rules(:cms)

    %{
      general: rules.general |> Enum.map(fn x -> {x, false} end) |> Map.new() |> Jason.encode!(),
      community:
        rules.community |> Enum.map(fn x -> {x, false} end) |> Map.new() |> Jason.encode!()
    }
  end
end

# 可以编辑某个社区 post 版块的文章, 支持 owner
# middleware(M.Passport, claim: "cms->c?->posts.article.edit")
# middleware(M.Passport, claim: "owner;cms->c?->posts.article.edit")

# 可以添加某个社区 posts 版块的 article_tag 标签, 同时可支持 owner
# middleware(M.Passport, claim: "cms->c?->posts.article_tag.add")
# middleware(M.Passport, claim: "cms->c?->posts.article_tag.edit")
# middleware(M.Passport, claim: "cms->c?->posts.article_tag.delete")
# middleware(M.Passport, claim: "owner;cms->c?->posts.article_tag.delete")

# 可以给某个社区 posts 版块的 posts 设置标签(setTag), 同时可支持 owner?
# middleware(M.Passport, claim: "c?->posts.article_tag.set")

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
