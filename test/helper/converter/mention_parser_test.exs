defmodule GroupherServer.Test.Helper.Converter.MentionParser do
  @moduledoc """
  parse mention(@) from given string
  """
  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.MentionParser

  @test_message ~S"""
  @you http://example.com/test?a=1&b=abc+123#abc
  this is a #test #message with #a few #test tags from +me @you and @中文我 xxx@email.com

  this is a #test #message with #a few #test tags from +me @you2 and @中文我 xxx@email.com
  """

  test "parse should return an empty for blank input" do
    ret = MentionParser.parse("", :mentions)

    assert ret == []
  end

  test "mention should parsed in list" do
    ret = MentionParser.parse(@test_message, :mentions)

    assert ret == ["@you", "@you2"]
  end

  test "email should not be parsed" do
    ret = MentionParser.parse(@test_message, :mentions)

    assert "xxx@email.com" not in ret
    assert "@email" not in ret
    assert "@email.com" not in ret
  end
end
