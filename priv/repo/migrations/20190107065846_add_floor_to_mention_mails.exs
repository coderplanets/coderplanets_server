defmodule GroupherServer.Repo.Migrations.AddFloorToMentionMails do
  use Ecto.Migration

  def change do
    alter table(:mention_mails) do
      add(:floor, :integer)
    end
  end
end
