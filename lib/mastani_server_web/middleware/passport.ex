# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
# RBAC vs CBAC
# https://stackoverflow.com/questions/22814023/role-based-access-control-rbac-vs-claims-based-access-control-cbac-in-asp-n

# 本中间件会隐式的加载 community 的 rules 信息，并应用该 rules 信息
defmodule MastaniServerWeb.Middleware.Passport do
  @moduledoc """
  c? -> community / communities
  p? -> thread, could be post / job / tut / video ...
  """
  @behaviour Absinthe.Middleware

  import Helper.Utils

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(%{arguments: %{passport_is_owner: true}} = resolution, claim: "owner"), do: resolution

  def call(%{arguments: %{passport_is_owner: true}} = resolution, claim: "owner;" <> _rest),
    do: resolution

  def call(
        %{
          context: %{cur_user: %{cur_passport: _}},
          arguments: %{community: _, thread: _}
        } = resolution,
        claim: "cms->c?->p?." <> _rest = claim
      ) do
    resolution |> check_passport_stamp(claim)
  end

  def call(
        %{
          context: %{cur_user: %{cur_passport: _}},
          arguments: %{thread: _}
        } = resolution,
        claim: "cms->p?." <> _rest = claim
      ) do
    resolution |> check_passport_stamp(claim)
  end

  def call(
        %{
          context: %{cur_user: %{cur_passport: _}},
          arguments: %{passport_communities: _}
        } = resolution,
        claim: "cms->c?->" <> _rest = claim
      ) do
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

  def call(
        %{context: %{cur_user: %{cur_passport: _}}} = resolution,
        claim: "cms->community." <> _rest = claim
      ) do
    resolution |> check_passport_stamp(claim)
  end

  def call(
        %{context: %{cur_user: %{cur_passport: _}}} = resolution,
        claim: "cms->thread." <> _rest = claim
      ) do
    resolution |> check_passport_stamp(claim)
  end

  def call(
        %{context: %{cur_user: %{cur_passport: _}}} = resolution,
        claim: "cms->editor." <> _rest = claim
      ) do
    resolution |> check_passport_stamp(claim)
  end

  def call(
        %{context: %{cur_user: %{cur_passport: _}}} = resolution,
        claim: "cms->category." <> _rest = claim
      ) do
    resolution |> check_passport_stamp(claim)
  end

  def call(resolution, _) do
    resolution |> handle_absinthe_error("PassportError: your passport not qualified.")
  end

  defp check_passport_stamp(resolution, claim) do
    cond do
      claim |> String.starts_with?("cms->community.") ->
        resolution |> do_check(claim)

      claim |> String.starts_with?("cms->editor.") ->
        resolution |> do_check(claim)

      claim |> String.starts_with?("cms->thread.") ->
        resolution |> do_check(claim)

      claim |> String.starts_with?("cms->category.") ->
        resolution |> do_check(claim)

      claim |> String.starts_with?("cms->c?->p?.") ->
        resolution |> cp_check(claim)

      claim |> String.starts_with?("cms->p?.") ->
        resolution |> p_check(claim)

      claim |> String.starts_with?("cms->c?->") ->
        resolution |> c_check(claim)

      true ->
        resolution |> handle_absinthe_error("PassportError: Passport not qualified.")
    end
  end

  defp do_check(resolution, claim) do
    cur_passport = resolution.context.cur_user.cur_passport
    path = claim |> String.split("->")

    case get_in(cur_passport, path) do
      true -> resolution
      nil -> resolution |> handle_absinthe_error("PassportError: Passport not qualified.")
    end
  end

  defp p_check(resolution, claim) do
    cur_passport = resolution.context.cur_user.cur_passport
    thread = resolution.arguments.thread |> to_string

    path =
      claim
      |> String.replace("p?", thread)
      |> String.split("->")

    case get_in(cur_passport, path) do
      true -> resolution
      nil -> resolution |> handle_absinthe_error("PassportError: Passport not qualified.")
    end
  end

  defp cp_check(resolution, claim) do
    cur_passport = resolution.context.cur_user.cur_passport
    community_title = resolution.arguments.passport_communities |> List.first() |> Map.get(:title)
    thread = resolution.arguments.thread |> to_string

    path =
      claim
      |> String.replace("c?", community_title)
      |> String.replace("p?", thread)
      |> String.split("->")

    case get_in(cur_passport, path) do
      true -> resolution
      nil -> resolution |> handle_absinthe_error("PassportError: Passport not qualified.")
    end
  end

  defp c_check(resolution, claim) do
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
