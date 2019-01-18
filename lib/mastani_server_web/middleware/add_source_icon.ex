# ---
# parse and add source icon to radar posts
# ---
defmodule MastaniServerWeb.Middleware.AddSourceIcon do
  @moduledoc """
  parse and add source icon to radar posts
  """
  @behaviour Absinthe.Middleware

  @parse_error "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/radar_source/url_parse_waning.png"
  @wanqu "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/radar_source/wanqu.png"
  @solidot "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/radar_source/solidot.png"
  @techcrunch "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/radar_source/techcrunch.png"
  @default_radar "https://cps-oss.oss-cn-shanghai.aliyuncs.com/icons/radar_source/default_radar.png"

  def call(%{arguments: %{topic: "radar"} = arguments} = resolution, _) do
    link_icon = parse_source_addr(arguments)
    %{resolution | arguments: Map.merge(arguments, %{link_icon: link_icon})}
  end

  def call(resolution, _), do: resolution

  defp parse_source_addr(%{link_addr: link_addr}) do
    result = URI.parse(link_addr)

    case Map.get(result, :host) do
      nil -> source_addr(:error)
      host -> source_addr(host)
    end
  end

  defp parse_source_addr(_), do: @default_radar

  defp source_addr("wanqu.co"), do: @wanqu
  defp source_addr("www.solidot.org"), do: @solidot
  defp source_addr("techcrunch.cn"), do: @techcrunch
  defp source_addr("techcrunch.com"), do: @techcrunch

  defp source_addr(:error), do: @parse_error
  defp source_addr(_), do: @default_radar
end
