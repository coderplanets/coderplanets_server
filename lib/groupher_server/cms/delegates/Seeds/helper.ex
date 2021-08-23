defmodule GroupherServer.CMS.Delegate.Seeds.Helper do
  @moduledoc false

  alias GroupherServer.CMS
  alias CMS.Delegate.SeedsConfig
  alias CMS.Model.Community

  alias Helper.ORM

  def insert_community(bot, raw, type) do
    type = Atom.to_string(type)
    ext = if Enum.member?(SeedsConfig.svg_icons(), raw), do: "svg", else: "png"

    args = %{
      title: SeedsConfig.trans(raw),
      aka: raw,
      desc: "#{raw} is awesome!",
      logo: "#{@oss_endpoint}/icons/#{type}/#{raw}.#{ext}",
      raw: raw,
      user_id: bot.id
    }

    ORM.create(Community, args)
  end
end
