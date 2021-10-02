defmodule GroupherServer.Repo.Migrations.AddMoreFieldsToWorks do
  use Ecto.Migration

  # - embeds_many social_info
  # - home_link
  # - profit_mode
  # - fulltime / parttime
  # - embeds_many city_info
  # - embed_many app_store
  # - embeds_many teammate
  # - embeds_many techstack

  # - community_link
  # interview
  ## mailstone

  def change do
    alter table(:cms_works) do
      add(:home_link, :string)
      add(:profit_mode, :string)
      add(:working_mode, :string)

      add(:social_info, :map)
      add(:city_info, :map)
      add(:app_store, :map)
      add(:teammate, :map)
      add(:techstack, :map)

      add(:community_link, :string)
      add(:interview_link, :string)
    end
  end
end
