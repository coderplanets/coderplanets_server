defmodule GroupherServer.Test.Helper.Converter.EditorToHtml do
  @moduledoc false

  #   import Helper.Utils, only: [get_config: 2]
  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHtml, as: Parser

  #   @article_viewer_tag get_config(:general, :article_viewer_tag)

  @real_editor_data ~S({
    "time" : 1567250876713,
    "blocks" : [
        {
            "type" : "paragraph",
            "data" : {
                "text" : "Hey. Meet the new Editor. On this page you can see it in action — try to edit this text."
            }
        },
        {
            "type" : "header",
            "data" : {
                "text" : "Editor.js",
                "level" : 2
            }
        },
        {
            "type" : "header",
            "data" : {
                "text" : "Key features",
                "level" : 3
            }
        },
        {
            "type" : "list",
            "data" : {
                "style" : "unordered",
                "items" : [
                    "It is a block-styled editor",
                    "It returns clean data output in JSON",
                    "Designed to be extendable and pluggable with a simple API"
                ]
            }
        },
        {
            "type" : "header",
            "data" : {
                "text" : "Key features",
                "level" : 3
            }
        },
        {
            "type" : "list",
            "data" : {
                "style" : "ordered",
                "items" : [
                    "It is a block-styled editor",
                    "It returns clean data output in JSON",
                    "Designed to be extendable and pluggable with a simple API"
                ]
            }
        },
        {
            "type" : "header",
            "data" : {
                "text" : "What does it mean «block-styled editor»",
                "level" : 3
            }
        },
        {
          "type" : "checklist",
          "data" : {
              "items" : [
                  {
                    "text" : "This is a block-styled editor",
                    "checked" : true
                  },
                  {
                    "text" : "Clean output data",
                    "checked" : false
                  },
                  {
                    "text" : "Simple and powerful API",
                    "checked" : true
                  }
              ]
          }
        },
        {
            "type" : "paragraph",
            "data" : {
                "text" : "Workspace in classic editors is made of a single contenteditable element, used to create different HTML markups. Editor.js <mark class=\"cdx-marker\">workspace consists of separate Blocks: paragraphs, headings, images, lists, quotes, etc</mark>. Each of them is an independent contenteditable element (or more complex structure\) provided by Plugin and united by Editor's Core."
            }
        },
        {
            "type" : "paragraph",
            "data" : {
                "text" : "There are dozens of <a href=\"https://github.com/editor-js\">ready-to-use Blocks</a> and the <a href=\"https://editorjs.io/creating-a-block-tool\">simple API</a> for creation any Block you need. For example, you can implement Blocks for Tweets, Instagram posts, surveys and polls, CTA-buttons and even games."
            }
        },
        {
            "type" : "header",
            "data" : {
                "text" : "What does it mean clean data output",
                "level" : 3
            }
        },
        {
            "type" : "paragraph",
            "data" : {
                "text" : "Classic WYSIWYG-editors produce raw HTML-markup with both content data and content appearance. On the contrary, Editor.js outputs JSON object with data of each Block. You can see an example below"
            }
        },
        {
            "type" : "paragraph",
            "data" : {
                "text" : "Given data can be used as you want: render with HTML for <code class=\"inline-code\">Web clients</code>, render natively for <code class=\"inline-code\">mobile apps</code>, create markup for <code class=\"inline-code\">Facebook Instant Articles</code> or <code class=\"inline-code\">Google AMP</code>, generate an <code class=\"inline-code\">audio version</code> and so on."
            }
        },
        {
            "type" : "paragraph",
            "data" : {
                "text" : "Clean data is useful to sanitize, validate and process on the backend."
            }
        },
        {
            "type" : "delimiter",
            "data" : {}
        },
        {
            "type" : "paragraph",
            "data" : {
                "text" : "We have been working on this project more than three years. Several large media projects help us to test and debug the Editor, to make it's core more stable. At the same time we significantly improved the API. Now, it can be used to create any plugin for any task. Hope you enjoy. 😏"
            }
        },
        {
            "type" : "image",
            "data" : {
                "file" : {
                    "url" : "https://codex.so/upload/redactor_images/o_e48549d1855c7fc1807308dd14990126.jpg"
                },
                "caption" : "",
                "withBorder" : true,
                "stretched" : false,
                "withBackground" : false
            }
        },
        {
            "type" : "linkTool",
            "data" : {
                "link" : "https://www.github.com",
                "meta" : {
                    "url" : "https://www.github.com",
                    "domain" : "www.github.com",
                    "title" : "Build software better, together",
                    "description" : "GitHub is where people build software. More than 40 million people use GitHub to discover, fork, and contribute to over 100 million projects.",
                    "image" : {
                        "url" : "https://github.githubassets.com/images/modules/open_graph/github-logo.png"
                    }
                }
            }
        },
        {
            "type" : "quote",
            "data" : {
                "text" : "quote demo text",
                "caption" : "desc?",
                "alignment" : "left"
            }
        },
        {
            "type" : "delimiter",
            "data" : {
                "type" : "pen"
            }
        },
        {
            "type" : "code",
            "data" : {
                "lang" : "js",
                "text" : "<script>evil scripts</script>"
            }
        }
    ],
    "version" : "2.15.0"
  })

  describe "[basic convert]" do
    test "basic string_json parse should work" do
      string = ~S({"time":1566184478687,"blocks":[{}],"version":"2.15.0"})
      {:ok, converted} = Parser.string_to_json(string)

      assert converted["version"] == "2.15.0"
    end

    test "invalid string data should get error" do
      string = ~S({"time":1566184478687,"blocks":[{}],"version":})
      assert {:error, converted} = Parser.string_to_json(string)
    end

    test "real-world editor.js data should work" do
      {:ok, converted} = Parser.string_to_json(@real_editor_data)

      assert not Enum.empty?(converted["blocks"])
      assert converted["blocks"] |> is_list
      assert converted["version"] |> is_binary
      assert converted["time"] |> is_integer
    end
  end

  describe "[block unit parse]" do
    @editor_data ~S({
        "time" : 1567250876713,
        "blocks" : [
            {
                "type" : "paragraph",
                "data" : {
                    "text" : "paragraph content"
                }
            }
        ],
        "version" : "2.15.0"
      })
    test "paragraph parse should work" do
      {:ok, converted} = Parser.to_html(@editor_data)

      assert converted == "<div class=\"article-viewer-wrapper\"><p>paragraph content</p><div>"
    end

    @editor_json %{
      "time" => 1_567_250_876_713,
      "blocks" => [
        %{
          "type" => "header",
          "data" => %{
            "text" => "header content",
            "level" => 1
          }
        },
        %{
          "type" => "header",
          "data" => %{
            "text" => "header content",
            "level" => 2
          }
        },
        %{
          "type" => "header",
          "data" => %{
            "text" => "header content",
            "level" => 3
          }
        }
      ],
      "version" => "2.15.0"
    }
    @tag :wip
    test "header parse should work" do
      {:ok, editor_string} = Jason.encode(@editor_json)
      {:ok, converted} = Parser.to_html(editor_string)

      assert converted ==
               "<div class=\"article-viewer-wrapper\"><h1>header content</h1><h2>header content</h2><h3>header content</h3><div>"
    end

    test "code block should avoid potential xss script attack" do
      {:ok, converted} = Parser.to_html(@real_editor_data)

      safe_script =
        "<pre><code class=\"lang-js\">&lt;script&gt;evil scripts&lt;/script&gt;</code></pre>"

      assert converted |> String.contains?(safe_script)
    end
  end
end
