defmodule GroupherServer.Repo.Migrations.CreateCommunitiesJoinMeetups do
  use Ecto.Migration

  def change do
    create table(:communities_join_meetups) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:meetup_id, references(:cms_meetups, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_join_meetups, [:community_id, :meetup_id]))
  end
end
