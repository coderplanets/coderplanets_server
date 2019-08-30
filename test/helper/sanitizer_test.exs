defmodule GroupherServer.Test.Helper.Sanitizer do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.RichTextParser, as: Parser
  alias Helper.Sanitizer

  describe "[snaitizer test]" do
    @tag :wip
    test "should strip p h1-6 etc tags" do
      html = "<p>hello</p><h1>1</h1><h2>2</h2><h3>3</h3><h4>4</h4><h5>5</h5><h6>6</h6>world"

      assert Sanitizer.sanitize(html) == "hello123456world"
    end

    @tag :wip
    test "disallow ftp urls" do
      html = "This is <a href=\"ftp://ftp.google.com/test\">FTP test</a>"

      assert Sanitizer.sanitize(html) == "This is <a>FTP test</a>"
    end

    @tag :wip
    test "alow <a/> with name and title " do
      html =
        "This is <a href=\"http://coderplanets.com/post/1\" name=\"name\" title=\"title\" other=\"other\">cps</a>"

      assert Sanitizer.sanitize(html) ==
               "This is <a href=\"http://coderplanets.com/post/1\" name=\"name\" title=\"title\">cps</a>"
    end

    @tag :wip
    test "allow mark tag with class attr" do
      html = "This <p>is</p> <mark class=\"cool-look\" other=\"other\">mark text</mark>"
      assert Sanitizer.sanitize(html) == "This is <mark class=\"cool-look\">mark text</mark>"
    end

    @tag :wip
    test "allow code tag with class attr" do
      html = "This <p>is</p> <code class=\"cool-look\" other=\"other\">code string</code>"
      assert Sanitizer.sanitize(html) == "This is <code class=\"cool-look\">code string</code>"
    end

    @tag :wip
    test "allow b tag with no attr" do
      html = "This <p>is</p> <b class=\"cool-look\" other=\"other\">text</b>"
      assert Sanitizer.sanitize(html) == "This is <b>text</b>"
    end

    @tag :wip
    test "allow i tag with no attr" do
      html = "This <p>is</p> <i class=\"cool-look\" other=\"other\">text</i>"
      assert Sanitizer.sanitize(html) == "This is <i>text</i>"
    end
  end
end
