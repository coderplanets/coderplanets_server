defmodule GroupherServer.Repo.Migrations.ReplaceStringToTextInJobComments do
  use Ecto.Migration

  def change do
    alter table(:jobs_comments) do
      remove(:body)
      add(:body, :text)
    end
  end
end
