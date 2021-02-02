defmodule GroupherServer.Test.Helper.Converter.HtmlSanitizer do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  # alias Helper.RichTextParser, as: Parser
  alias Helper.Converter.HtmlSanitizer, as: Sanitizer

  describe "[snaitizer test]" do
    test "should strip p h4-6 etc tags" do
      html =
        "<form>hello</form><h4>1</h4><h5>2</h5><h6>3</h6><h4>4</h4><h5>5</h5><h6>6</h6><h1>world</h1><h2>world2</h2><h3>world3</h3>"

      assert Sanitizer.sanitize(html) == "hello123456<h1>world</h1><h2>world2</h2><h3>world3</h3>"
    end

    test "disallow ftp urls" do
      html = "This is <a href=\"ftp://ftp.google.com/test\">FTP test</a>"

      assert Sanitizer.sanitize(html) == "This is <a>FTP test</a>"
    end

    test "alow <a/> with name and title " do
      html =
        "This is <a href=\"http://coderplanets.com/post/1\" name=\"name\" title=\"title\" other=\"other\">cps</a>"

      assert Sanitizer.sanitize(html) ==
               "This is <a href=\"http://coderplanets.com/post/1\" name=\"name\" title=\"title\">cps</a>"
    end

    test "allow mark tag with class attr" do
      html = "This <form>is</form> <mark class=\"cool-look\" other=\"other\">mark text</mark>"
      assert Sanitizer.sanitize(html) == "This is <mark class=\"cool-look\">mark text</mark>"
    end

    test "allow code tag with class attr" do
      html = "This <form>is</form> <code class=\"cool-look\" other=\"other\">code string</code>"
      assert Sanitizer.sanitize(html) == "This is <code class=\"cool-look\">code string</code>"
    end

    test "allow b tag with no attr" do
      html = "This <form>is</form> <b class=\"cool-look\" other=\"other\">text</b>"
      assert Sanitizer.sanitize(html) == "This is <b>text</b>"
    end

    test "allow i tag with no attr" do
      html = "This <form>is</form> <i class=\"cool-look\" other=\"other\">text</i>"
      assert Sanitizer.sanitize(html) == "This is <i>text</i>"
    end

    test "allow iframe with valid attr" do
      html = """
      <iframe sandbox="allow-scripts allow-same-origin allow-presentation" src="addr" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen="" style="width: 100%; height: 300px;" invalidprops></iframe>
      """

      assert Sanitizer.sanitize(html) ==
               "<iframe sandbox=\"allow-scripts allow-same-origin allow-presentation\" src=\"addr\" frameborder=\"0\" allow=\"autoplay; encrypted-media\" allowfullscreen=\"\" style=\"width: 100%; height: 300px;\"></iframe>\n"
    end
  end
end
