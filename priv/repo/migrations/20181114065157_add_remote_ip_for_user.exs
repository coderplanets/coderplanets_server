defmodule GroupherServer.Repo.Migrations.AddRemoteIpForUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:remote_ip, :string)
    end
  end
end
