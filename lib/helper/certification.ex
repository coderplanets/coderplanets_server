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
        "post.community.set",
        "post.community.unset",
        "job.community.set",
        "job.community.unset",
        "post.pin",
        "post.unpin"
      ],
      community: [
        # thread
        "thread.set",
        "thread.unset",
        "post.edit",
        "post.trash",
        "post.delete",
        "job.edit",
        "job.trash",
        "job.delete",
        # post tag
        "post.tag.create",
        "post.tag.update",
        "post.tag.delete",
        "post.tag.set",
        "post.tag.unset",
        # job tag
        "job.tag.create",
        "job.tag.update",
        "job.tag.delete",
        "job.tag.set",
        "job.tag.unset"
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
