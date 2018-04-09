# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
# RBAC vs CBAC
# https://stackoverflow.com/questions/22814023/role-based-access-control-rbac-vs-claims-based-access-control-cbac-in-asp-n

# 本中间件会隐式的加载 community 的 rules 信息，并应用该 rules 信息
defmodule MastaniServerWeb.Middleware.Passport do
  @behaviour Absinthe.Middleware

  import Helper.Utils

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(%{arguments: %{passport_is_owner: true}} = resolution, claim: "owner"), do: resolution

  def call(%{arguments: %{passport_is_owner: true}} = resolution, claim: "owner;" <> _rest),
    do: resolution

  def call(
        %{
          context: %{cur_user: %{cur_passport: _}},
          arguments: %{community: _, part: _}
        } = resolution,
        claim: "cms->c?->p?." <> _rest = claim
      ) do
    # IO.inspect("catch me cms->c?->p?", label: "[passport]")
    resolution |> check_passport_stamp(claim)
  end

  def call(
        %{
          context: %{cur_user: %{cur_passport: _}},
          arguments: %{passport_communities: _}
        } = resolution,
        claim: "cms->c?->" <> _rest = claim
      ) do
    # IO.inspect("catch me cms->c?->", label: "[passport]")
    resolution |> check_passport_stamp(claim)
  end

  def call(
        %{
          context: %{cur_user: %{cur_passport: _}},
          arguments: %{passport_communities: _}
        } = resolution,
        claim: "owner;" <> claim
      ) do
    resolution |> check_passport_stamp(claim)
  end

  def call(resolution, _) do
    resolution |> handle_absinthe_error("PassportError: your passport not qualified.")
  end

  defp check_passport_stamp(resolution, claim) do
    cond do
      claim |> String.starts_with?("cms->c?->p?.") ->
        resolution |> two_step_check(claim)

      claim |> String.starts_with?("cms->c?->") ->
        resolution |> one_step_check(claim)

      true ->
        resolution |> handle_absinthe_error("PassportError: Passport not qualified.")
    end
  end

  defp two_step_check(resolution, claim) do
    cur_passport = resolution.context.cur_user.cur_passport
    community = resolution.arguments.community
    part = resolution.arguments.part |> to_string

    path =
      claim
      |> String.replace("c?", community)
      |> String.replace("p?", part)
      |> String.split("->")

    case get_in(cur_passport, path) do
      true -> resolution
      nil -> resolution |> handle_absinthe_error("PassportError: Passport not qualified.")
    end
  end

  defp one_step_check(resolution, claim) do
    cur_passport = resolution.context.cur_user.cur_passport
    communities = resolution.arguments.passport_communities

    result =
      communities
      |> Enum.filter(fn community ->
        path = claim |> String.replace("c?", community.title) |> String.split("->")
        get_in(cur_passport, path) == true
      end)
      |> length

    case result > 0 do
      true -> resolution
      false -> resolution |> handle_absinthe_error("PassportError: Passport not qualified.")
    end
  end
end

# 可以编辑某个社区 post 版块的文章, 支持 owner
# middleware(M.Passport, claim: "cms->c?->posts.articles.edit")
# middleware(M.Passport, claim: "owner;cms->c?->posts.articles.edit")

# 可以添加某个社区 posts 版块的 tag 标签, 同时可支持 owner
# middleware(M.Passport, claim: "cms->c?->posts.tag.add")
# middleware(M.Passport, claim: "cms->c?->posts.tag.edit")
# middleware(M.Passport, claim: "cms->c?->posts.tag.delete")
# middleware(M.Passport, claim: "cms->c?->posts.tag.trash")
# middleware(M.Passport, claim: "owner;cms->c?->posts.tag.delete")

# 可以给某个社区 posts 版块的 posts 设置标签(setTag), 同时可支持 owner?
# middleware(M.Passport, claim: "c?->posts.setTag")

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
