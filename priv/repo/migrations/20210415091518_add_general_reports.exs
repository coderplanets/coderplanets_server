defmodule GroupherServer.Repo.Migrations.AddGeneralReports do
  use Ecto.Migration

  def change do
    create table(:abuse_reports) do
      # 举报人们
      add(:report_cases, :map)
      # has many
      # [
      #   %{
      #     user,
      #     reason,
      #     additional_reason,
      #     timestamp
      #   }
      # ]

      # 举报用户人次
      add(:report_cases_count, :integer, default: 0)

      # 举报账户
      add(:account_id, references(:users, on_delete: :delete_all))
      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))
      add(:article_comment_id, references(:articles_comments, on_delete: :delete_all))

      # 处理人
      add(:operate_user_id, references(:users, on_delete: :delete_all))
      add(:deal_with, :string)

      # 一旦处理完就不在接受举报了
      add(:is_closed, :boolean, default: false)

      timestamps()
    end

    create(index(:abuse_reports, [:account_id]))
    create(index(:abuse_reports, [:post_id]))
    create(index(:abuse_reports, [:job_id]))
    create(index(:abuse_reports, [:article_comment_id]))
    create(index(:abuse_reports, [:operate_user_id]))
  end
end
