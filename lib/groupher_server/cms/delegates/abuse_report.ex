defmodule GroupherServer.CMS.Delegate.AbuseReport do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1]

  import GroupherServer.CMS.Helper.Matcher2
  import ShortMaps

  alias Helper.ORM
  alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{AbuseReport, Embeds}

  alias Ecto.Multi

  # filter = %{
  #   contentType: account | post | job | repo | article_comment
  #   contentId: ...
  #   operate_user_id,
  #   min_case_count,
  #   max_case_count,
  #   is_closed
  #   page
  #   size
  # }

  # def list_all_reports(thread, filter)
  # def list_all_reports(community, filter)
  # def list_all_reports(filter)
  @article_threads [:post, :job, :repo]
  @export_report_keys [
    :id,
    :deal_with,
    :is_closed,
    :operate_user,
    :report_cases,
    :report_cases_count,
    :inserted_at,
    :updated_at
  ]

  def list_reports(%{content_type: thread, content_id: content_id} = filter)
      when thread in @article_threads do
    %{page: page, size: size} = filter

    with {:ok, info} <- match(thread) do
      query =
        from(r in AbuseReport,
          where: field(r, ^info.foreign_key) == ^content_id,
          preload: [^thread, :operate_user]
        )

      query
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> reports_formater(thread)
      |> done()
    end
  end

  defp reports_formater(%{entries: entries} = paged_reports, thread)
       when thread in @article_threads do
    paged_reports
    |> Map.put(
      :entries,
      Enum.map(entries, fn report ->
        basic_report = report |> Map.take(@export_report_keys)
        basic_report |> Map.put(:article, extract_article_info(thread, report))
      end)
    )
  end

  defp extract_article_info(thread, %AbuseReport{} = report) do
    article = Map.get(report, thread)

    %{
      thread: thread,
      id: article.id,
      title: article.title,
      digest: article.digest,
      upvotes_count: article.upvotes_count,
      views: article.views
    }
  end

  @doc """
  list paged reports for both comment and article
  """
  def list_reports(thread, content_id, %{page: page, size: size} = filter) do
    with {:ok, info} <- match(thread) do
      query =
        from(r in AbuseReport,
          where: field(r, ^info.foreign_key) == ^content_id,
          preload: [^thread, :operate_user]
        )

      query
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  @doc """
  report article content
  """
  def report_article(thread, article_id, reason, attr, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:create_abuse_report, fn _, _ ->
        create_report(thread, article_id, reason, attr, user)
      end)
      |> Multi.run(:update_report_flag, fn _, _ ->
        update_report_meta(info, article, true)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def undo_report_article_comment(comment_id, %User{} = user) do
    undo_report_article(:article_comment, comment_id, user)
  end

  @doc """
  undo report article content
  """
  def undo_report_article(thread, article_id, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:delete_abuse_report, fn _, _ ->
        delete_report(thread, article_id, user)
      end)
      |> Multi.run(:update_report_flag, fn _, _ ->
        update_report_meta(info, article, false)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def create_report(type, content_id, reason, attr, %User{} = user) do
    with {:ok, info} <- match(type),
         {:ok, report} <- not_reported_before(info, content_id, user) do
      case report do
        nil ->
          report_cases = [
            %{
              reason: reason,
              attr: attr,
              user: %{login: user.login, nickname: user.nickname}
            }
          ]

          args =
            %{report_cases_count: 1, report_cases: report_cases}
            |> Map.put(info.foreign_key, content_id)

          AbuseReport |> ORM.create(args)

        _ ->
          user = %{login: user.login, nickname: user.nickname}

          report_cases =
            report.report_cases
            |> List.insert_at(
              length(report.report_cases),
              %Embeds.AbuseReportCase{reason: reason, attr: attr, user: user}
            )

          report
          |> Ecto.Changeset.change(%{report_cases_count: length(report_cases)})
          |> Ecto.Changeset.put_embed(:report_cases, report_cases)
          |> Repo.update()
      end
    end
  end

  defp delete_report(thread, content_id, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:error, _} <- not_reported_before(info, content_id, user),
         {:ok, report} = ORM.find_by(AbuseReport, Map.put(%{}, info.foreign_key, content_id)) do
      case length(report.report_cases) do
        1 ->
          ORM.delete(report)

        _ ->
          report_cases = report.report_cases |> Enum.reject(&(&1.user.login == user.login))

          report
          |> Ecto.Changeset.change(%{report_cases_count: length(report_cases)})
          |> Ecto.Changeset.put_embed(:report_cases, report_cases)
          |> Repo.update()
      end
    end
  end

  # update is_reported flag and reported_count in mete for article or comment
  defp update_report_meta(info, content, is_reported) do
    case ORM.find_by(AbuseReport, Map.put(%{}, info.foreign_key, content.id)) do
      {:ok, record} ->
        reported_count = record.report_cases |> length
        meta = content.meta |> Map.merge(%{reported_count: reported_count}) |> strip_struct

        content
        |> Ecto.Changeset.change(%{is_reported: is_reported})
        |> Ecto.Changeset.put_embed(:meta, meta)
        |> Repo.update()

      {:error, _} ->
        meta = content.meta |> Map.merge(%{reported_count: 0}) |> strip_struct

        content
        |> Ecto.Changeset.change(%{is_reported: false})
        |> Ecto.Changeset.put_embed(:meta, meta)
        |> Repo.update()
    end
  end

  defp not_reported_before(info, content_id, %User{login: login}) do
    query = from(r in AbuseReport, where: field(r, ^info.foreign_key) == ^content_id)

    report = Repo.one(query)

    case report do
      nil ->
        {:ok, nil}

      _ ->
        reported_before =
          report.report_cases
          |> Enum.filter(fn item -> item.user.login == login end)
          |> length
          |> Kernel.>(0)

        if not reported_before, do: {:ok, report}, else: {:error, "#{login} already reported"}
    end
  end

  defp result({:ok, %{update_report_flag: result}}), do: result |> done()

  defp result({:error, _, result, _steps}) do
    {:error, result}
  end
end
