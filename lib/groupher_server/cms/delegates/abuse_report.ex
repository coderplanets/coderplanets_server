defmodule GroupherServer.CMS.Delegate.AbuseReport do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1, get_config: 2]

  import GroupherServer.CMS.Delegate.Helper, only: [sync_embed_replies: 1]

  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps

  alias Helper.ORM
  alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.Model.User
  alias CMS.Model.{AbuseReport, Comment, Embeds}

  alias Ecto.Multi

  @article_threads get_config(:article, :threads)
  @report_threshold_for_fold Comment.report_threshold_for_fold()

  @export_author_keys [:id, :login, :nickname, :avatar]
  @export_article_keys [:id, :title, :digest, :upvotes_count, :views]
  @export_report_keys [
    :id,
    :deal_with,
    :operate_user,
    :report_cases,
    :report_cases_count,
    :inserted_at,
    :updated_at
  ]

  @doc """
  list paged reports for article comemnts
  """
  def paged_reports(%{content_type: :account, content_id: content_id} = filter) do
    with {:ok, info} <- match(:account) do
      query =
        from(r in AbuseReport,
          where: field(r, ^info.foreign_key) == ^content_id,
          preload: :account
        )

      do_paged_reports(query, :account, filter)
    end
  end

  @doc """
  list paged reports for article comemnts
  """
  def paged_reports(%{content_type: :comment, content_id: content_id} = filter) do
    with {:ok, info} <- match(:comment) do
      query =
        from(r in AbuseReport,
          where: field(r, ^info.foreign_key) == ^content_id,
          preload: [comment: ^@article_threads],
          preload: [comment: :author]
        )

      do_paged_reports(query, :comment, filter)
    end
  end

  @doc """
  list paged reports for article
  """
  def paged_reports(%{content_type: thread, content_id: content_id} = filter)
      when thread in @article_threads do
    with {:ok, info} <- match(thread) do
      query =
        from(r in AbuseReport,
          where: field(r, ^info.foreign_key) == ^content_id,
          preload: [^thread, :operate_user]
        )

      do_paged_reports(query, thread, filter)
    end
  end

  # def paged_reports(%{content_type: thread} = filter) when thread in @article_threads do
  def paged_reports(%{content_type: thread} = filter) do
    with {:ok, info} <- match(thread) do
      query =
        from(r in AbuseReport,
          where: not is_nil(field(r, ^info.foreign_key)),
          preload: [^thread, :operate_user],
          preload: [comment: :author]
        )

      do_paged_reports(query, thread, filter)
    end
  end

  def paged_reports(filter) do
    query = from(r in AbuseReport, preload: [:operate_user])

    do_paged_reports(query, filter)
  end

  @doc """
  report an account
  """
  def report_account(account_id, reason, attr, user) do
    with {:ok, info} <- match(:account),
         {:ok, account} <- ORM.find(info.model, account_id) do
      Multi.new()
      |> Multi.run(:create_abuse_report, fn _, _ ->
        create_report(:account, account.id, reason, attr, user)
      end)
      |> Multi.run(:update_report_meta, fn _, _ ->
        update_report_meta(info, account)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  undo report article content
  """
  def undo_report_account(account_id, %User{} = user) do
    with {:ok, info} <- match(:account),
         {:ok, account} <- ORM.find(info.model, account_id) do
      Multi.new()
      |> Multi.run(:delete_abuse_report, fn _, _ ->
        delete_report(:account, account.id, user)
      end)
      |> Multi.run(:update_report_meta, fn _, _ ->
        update_report_meta(info, account)
      end)
      |> Repo.transaction()
      |> result()
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
        create_report(thread, article.id, reason, attr, user)
      end)
      |> Multi.run(:update_report_meta, fn _, _ ->
        update_report_meta(info, article)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  undo report article content
  """
  def undo_report_article(thread, article_id, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:delete_abuse_report, fn _, _ ->
        delete_report(thread, article.id, user)
      end)
      |> Multi.run(:update_report_meta, fn _, _ ->
        update_report_meta(info, article)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc "report a comment"
  def report_comment(comment_id, reason, attr, %User{} = user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id) do
      Multi.new()
      |> Multi.run(:create_abuse_report, fn _, _ ->
        create_report(:comment, comment_id, reason, attr, user)
      end)
      |> Multi.run(:update_report_meta, fn _, _ ->
        {:ok, info} = match(:comment)
        update_report_meta(info, comment)
      end)
      |> Multi.run(:fold_comment_report_too_many, fn _, %{create_abuse_report: abuse_report} ->
        if abuse_report.report_cases_count >= @report_threshold_for_fold,
          do: CMS.fold_comment(comment, user),
          else: {:ok, comment}
      end)
      |> Multi.run(:sync_embed_replies, fn _, %{update_report_meta: comment} ->
        sync_embed_replies(comment)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def undo_report_comment(comment_id, %User{} = user) do
    undo_report_article(:comment, comment_id, user)
  end

  defp do_paged_reports(query, thread, filter) do
    %{page: page, size: size} = filter

    query
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginator(~m(page size)a)
    |> reports_formater(thread)
    |> done()
  end

  defp do_paged_reports(query, %{page: page, size: size}) do
    query |> ORM.paginator(~m(page size)a) |> done()
  end

  defp create_report(type, content_id, reason, attr, %User{} = user) do
    with {:ok, info} <- match(type),
         {:ok, report} <- not_reported_before(info, content_id, user) do
      case report do
        nil ->
          report_cases = [
            %{
              reason: reason,
              attr: attr,
              user: %{user_id: user.id, login: user.login, nickname: user.nickname}
            }
          ]

          args =
            %{report_cases_count: 1, report_cases: report_cases}
            |> Map.put(info.foreign_key, content_id)

          AbuseReport |> ORM.create(args)

        _ ->
          user = %{user_id: user.id, login: user.login, nickname: user.nickname}

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

          changes = %{report_cases_count: length(report_cases)}

          report
          |> ORM.update_embed(:report_cases, report_cases, changes)
      end
    end
  end

  # update reported_count in mete for article | comment | account
  defp update_report_meta(info, content) do
    meta =
      case ORM.find_by(AbuseReport, Map.put(%{}, info.foreign_key, content.id)) do
        {:ok, record} ->
          report_cases = record.report_cases
          reported_count = length(report_cases)
          safe_meta = if is_nil(content.meta), do: info.default_meta, else: content.meta
          reported_user_ids = report_cases |> Enum.map(& &1.user.user_id)

          safe_meta
          |> Map.merge(%{reported_count: reported_count, reported_user_ids: reported_user_ids})
          |> strip_struct

        {:error, _} ->
          safe_meta = if is_nil(content.meta), do: info.default_meta, else: content.meta

          safe_meta |> Map.merge(%{reported_count: 0, reported_user_ids: []}) |> strip_struct
      end

    content |> ORM.update_meta(meta)
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

  defp reports_formater(%{entries: entries} = paged_reports, :account) do
    paged_reports
    |> Map.put(
      :entries,
      Enum.map(entries, fn report ->
        basic_report = report |> Map.take(@export_report_keys)
        basic_report |> Map.put(:account, extract_account_info(report))
      end)
    )
  end

  defp reports_formater(%{entries: entries} = paged_reports, :comment) do
    paged_reports
    |> Map.put(
      :entries,
      Enum.map(entries, fn report ->
        basic_report = report |> Map.take(@export_report_keys)
        basic_report |> Map.put(:comment, extract_article_comment_info(report))
      end)
    )
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

  defp extract_account_info(%AbuseReport{} = report) do
    report |> Map.get(:account) |> Map.take(@export_author_keys)
  end

  # TODO: original community and communities info
  defp extract_article_info(thread, %AbuseReport{} = report) do
    report
    |> Map.get(thread)
    |> Map.take(@export_article_keys)
    |> Map.merge(%{thread: thread |> to_string |> String.upcase()})
  end

  def extract_article_comment_info(%AbuseReport{} = report) do
    keys = [:id, :upvotes_count, :body_html]
    author = Map.take(report.comment.author, @export_author_keys)

    comment = Map.take(report.comment, keys)
    comment = Map.merge(comment, %{author: author})

    article = extract_article_in_comment(report.comment)
    Map.merge(comment, %{article: article})
  end

  defp extract_article_in_comment(%Comment{} = comment) do
    article_thread =
      Enum.filter(@article_threads, fn thread ->
        not is_nil(Map.get(comment, :"#{thread}_id"))
      end)
      |> List.first()

    comment
    |> Map.get(article_thread)
    |> Map.take(@export_article_keys)
    |> Map.merge(%{thread: article_thread})
  end

  defp result({:ok, %{sync_embed_replies: result}}), do: result |> done()
  defp result({:ok, %{update_report_meta: result}}), do: result |> done()
  defp result({:ok, %{update_content_reported_flag: result}}), do: result |> done()

  defp result({:error, _, result, _steps}) do
    {:error, result}
  end
end
