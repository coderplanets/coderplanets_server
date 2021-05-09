defmodule GroupherServer.CMS.Delegate.AbuseReport do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  # import Helper.Utils, only: [done: 1]

  import GroupherServer.CMS.Helper.Matcher2
  # import ShortMaps

  alias Helper.{ORM}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{AbuseReport, Embeds}

  # alias Accounts.User

  def create_report(type, content_id, %{reason: reason}, %User{} = user) do
    with {:ok, info} <- match(type),
         {:ok, report} <- not_reported_before(info, content_id, user) do
      case report do
        nil ->
          updated_report_cases = [
            %{
              reason: reason,
              additional_reason: "additional_reason",
              user: %{login: user.login, nickname: user.nickname}
            }
          ]

          args =
            %{report_cases_count: 1, report_cases: updated_report_cases}
            |> Map.put(info.foreign_key, content_id)

          AbuseReport |> ORM.create(args)

        _ ->
          updated_report_cases =
            report.report_cases
            |> List.insert_at(
              length(report.report_cases),
              %Embeds.AbuseReportCase{
                reason: reason,
                additional_reason: "additional_reason",
                user: %{login: user.login, nickname: user.nickname}
              }
            )

          report
          |> Ecto.Changeset.change(%{report_cases_count: length(updated_report_cases)})
          |> Ecto.Changeset.put_embed(:report_cases, updated_report_cases)
          |> Repo.update()
      end
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

        if not reported_before,
          do: {:ok, report},
          else: {:error, "#{login} already reported"}
    end
  end
end
