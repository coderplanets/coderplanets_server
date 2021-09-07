defmodule GroupherServer.Repo.Migrations.AddLinkToMeetup do
  use Ecto.Migration

  def change do
    alter table(:cms_meetups) do
      add(:link_addr, :string)
    end
  end
end
