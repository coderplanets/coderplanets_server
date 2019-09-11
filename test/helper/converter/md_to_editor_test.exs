defmodule GroupherServer.Test.Helper.Converter.MdToEditor do
  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.MdToEditor, as: Converter

  describe "[basic md test]" do
    @tag :wip
    test "ast parser should work" do
      mdstring = """

      ## hello

      this is a basic markdown text

      ### ~~delete me~~
      this is a basic markdown text

      ### _~~italic me~~_
      this is a basic markdown text
      """

      res = Converter.parse(mdstring)

      assert res ==
               [
                 %{data: %{level: 2, text: "hello"}, type: "header"},
                 %{
                   data: %{text: "this is a basic markdown text"},
                   type: "paragraph"
                 },
                 %{data: %{level: 3, text: "delete me"}, type: "header"},
                 %{
                   data: %{text: "this is a basic markdown text"},
                   type: "paragraph"
                 },
                 %{data: %{level: 3, text: "italic me"}, type: "header"},
                 %{
                   data: %{text: "this is a basic markdown text"},
                   type: "paragraph"
                 }
               ]

      # IO.inspect(res, label: "ast")

      # assert Sanitizer.sanitize(html) == "hello123456<h1>world</h1><h2>world2</h2><h3>world3</h3>"
    end

    @tag :wip2
    test "complex ast parser should work" do
      mdstring = """

      ## hello

      this is a basic *markdown* text

      ### ~~delete me~~

      ### _~~italic me~~_

      My `in-line-code-content` is **best**
      """

      res = Converter.parse(mdstring)

      # IO.inspect(res, label: "ast")

      # assert Sanitizer.sanitize(html) == "hello123456<h1>world</h1><h2>world2</h2><h3>world3</h3>"
    end
  end
end
