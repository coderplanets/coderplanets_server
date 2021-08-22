defmodule GroupherServer.CMS.Delegate.SeedsConfig do
  @moduledoc """
  init config for seeds
  """
  def svg_icons do
    [
      "feedback",
      "beijing",
      "shanghai",
      "shenzhen",
      "hangzhou",
      "guangzhou",
      "chengdu",
      "wuhan",
      "xiamen",
      "nanjing"
    ]
  end

  def trans("beijing"), do: "北京"
  def trans("shanghai"), do: "上海"
  def trans("shenzhen"), do: "深圳"
  def trans("hangzhou"), do: "杭州"
  def trans("guangzhou"), do: "广州"
  def trans("chengdu"), do: "成都"
  def trans("wuhan"), do: "武汉"
  def trans("xiamen"), do: "厦门"
  def trans("nanjing"), do: "南京"
  def trans(c), do: c
end
