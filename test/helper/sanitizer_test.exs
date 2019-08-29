defmodule GroupherServer.Test.Helper.Sanitizer do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.RichTextParser, as: Parser

  describe "[snaitizer test]" do
    @tag :wip
    test "basic test" do
      html = "hello<h1>1</h1><h2>2</h2><h3>3</h3><h4>4</h4><h5>5</h5><h6>6</h6>world"
      sanitized = Helper.Sanitizer.sanitize(html)
      assert sanitized = "hello123456world"
    end

    @tag :wip
    test "disallow ftp urls" do
      html = "<p>This is <a href=\"ftp://ftp.google.com/test\">FTP test</a></p>"
      sanitized = Helper.Sanitizer.sanitize(html)
      assert sanitized == "<p>This is <a>FTP test</a></p>"
    end
  end
end
