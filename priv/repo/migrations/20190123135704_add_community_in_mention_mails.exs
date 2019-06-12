defmodule GroupherServer.Repo.Migrations.AddCommunityInMentionMails do
  use Ecto.Migration

  def change do
    alter table(:mention_mails) do
      add(:community, :string)
    end
  end
end
