defmodule GroupherServer.Repo.Migrations.CreatePublishThrottle do
  use Ecto.Migration

  def change do
    create table(:publish_throttles) do
      add(:user_id, references(:users, on_delete: :delete_all, null: false))
      add(:publish_hour, :utc_datetime)
      add(:publish_date, :date)
      add(:hour_count, :integer)
      add(:date_count, :integer)

      add(:last_publish_time, :utc_datetime)
    end

    create(index(:publish_throttles, [:user_id]))
  end
end
