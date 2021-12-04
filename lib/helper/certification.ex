defmodule Helper.Certification do
  @moduledoc """
  valid editors and passport details
  """
  import Helper.Utils, only: [get_config: 2]

  @article_threads get_config(:article, :threads)
  @article_rules [
    "edit",
    "mark_delete",
    "undo_mark_delete",
    "delete",
    "community.mirror",
    "community.unmirror",
    "community.move",
    "pin",
    "undo_pin",
    "sink",
    "undo_sink",
    "lock_comment",
    "undo_lock_comment",
    "article_tag.create",
    "article_tag.update",
    "article_tag.delete",
    "article_tag.set",
    "article_tag.unset"
  ]

  def editor_titles(:cms) do
    ["chief editor", "post editor", "volunteer"]
  end

  def passport_rules(cms: "volunteer") do
    %{
      "post.article_tag.create" => true,
      "post.article_tag.edit" => true,
      "post.mark_delete" => true
    }
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

  defp build_article_rules(rule_list) do
    Enum.reduce(rule_list, [], fn rule, acc ->
      articles_rules = @article_threads |> Enum.map(&"#{&1}.#{rule}")
      acc ++ articles_rules
    end)
  end

  @doc """
  基础权限，社区权限
  """
  def all_rules(:cms) do
    %{
      general:
        build_article_rules(@article_rules) ++
          [
            "root",
            "blackeye",
            "homemirror",
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
            "community.apply.approve",
            "community.apply.deny"
            #
          ],
      community: [
        "thread.set",
        "thread.unset"
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
