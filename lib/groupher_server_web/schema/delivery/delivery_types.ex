defmodule GroupherServerWeb.Schema.Delivery.Types do
  use Absinthe.Schema.Notation

  import GroupherServerWeb.Schema.Helper.Fields
  import Helper.Utils, only: [get_config: 2]

  @page_size get_config(:general, :page_size)

  object :mail_box_status do
    field(:has_mail, :boolean)
    field(:total_count, :integer)
    field(:mention_count, :integer)
    field(:notification_count, :integer)
  end

  object :mention do
    field(:id, :id)
    field(:from_user_id, :id)
    field(:to_user_id, :id)
    field(:from_user, :user)
    field(:to_user, :user)

    field(:source_title, :string)
    field(:source_id, :string)
    field(:source_preview, :string)
    field(:source_type, :string)

    field(:parent_id, :string)
    field(:parent_type, :string)
    field(:floor, :integer)

    field(:community, :string)
    field(:read, :boolean)
  end

  # object :sys_notification do
  #   field(:id, :id)

  #   field(:source_id, :string)
  #   field(:source_title, :string)
  #   field(:source_preview, :string)
  #   field(:source_type, :string)

  #   field(:read, :boolean)
  # end

  object :notification do
    field(:id, :id)
    field(:from_user_id, :id)
    field(:to_user_id, :id)
    field(:action, :string)

    field(:source_id, :string)
    field(:source_title, :string)
    field(:source_preview, :string)
    field(:source_type, :string)
    field(:read, :boolean)
  end

  object :sys_notification do
    field(:id, :id)
    field(:user_id, :id)

    field(:source_id, :string)
    field(:source_title, :string)
    field(:source_preview, :string)
    field(:source_type, :string)
    field(:read, :boolean)
  end

  object :paged_mentions do
    field(:entries, list_of(:mention))
    pagination_fields()
  end

  object :paged_notifications do
    field(:entries, list_of(:notification))
    pagination_fields()
  end

  object :paged_sys_notifications do
    field(:entries, list_of(:sys_notification))
    pagination_fields()
  end

  input_object :messages_filter do
    field(:read, :boolean, default_value: false)

    field(:page, :integer, default_value: 1)
    field(:size, :integer, default_value: @page_size)
  end
end
