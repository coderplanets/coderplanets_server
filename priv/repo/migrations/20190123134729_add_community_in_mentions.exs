defmodule GroupherServer.Repo.Migrations.AddCommunityInMentions do
  use Ecto.Migration

  def change do
    alter table(:mentions) do
      add(:community, :string)
    end
  end
end
