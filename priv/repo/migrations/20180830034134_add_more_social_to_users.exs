defmodule MastaniServer.Repo.Migrations.AddMoreSocialToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:pinterest, :string)
      add(:instagram, :string)
    end
  end
end
