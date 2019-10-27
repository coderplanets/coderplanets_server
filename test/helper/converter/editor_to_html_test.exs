defmodule GroupherServer.Test.Helper.Converter.EditorToHtml do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.EditorToHtml, as: Parser

  @real_editor_data ~S({
    "time" : 1567250876713,
    "blocks" : [
        {
            "type" : "header",
            "data" : {
                "text" : "Editor.js",
                "level" : 2
            }
        },
        {
            "type" : "paragraph",
            "data" : {
                "text" : "Hey. Meet the new Editor. On this page you can see it in action — try to edit this text."
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
        }
    ],
    "version" : "2.15.0"
  })

  describe "[basic convert]" do
    test "basic string_json should work" do
      string = ~S({"time":1566184478687,"blocks":[{}],"version":"2.15.0"})
      {:ok, converted} = Parser.string_to_json(string)

      assert converted["time"] == 1_566_184_478_687
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

  describe "[block convert]" do
    # @tag :wip2
    # test "allow svg tag" do
    #   html = """
    #   <svg height="22px" width="22px" t="1572155354182" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="14479" width="200" height="200"><path d="M812.586667 331.306667h79.850666a71.338667 71.338667 0 0 1 71.317334 71.317333v86.784a158.122667 158.122667 0 0 1-158.101334 158.122667h-5.568c-38.890667 130.624-159.893333 225.877333-303.146666 225.877333h-120.469334c-174.656 0-316.224-141.589333-316.224-316.224V342.4a101.44 101.44 0 0 1 101.44-101.461333h550.037334a101.461333 101.461333 0 0 1 100.864 90.346666zM240.938667 60.224c16.64 0 30.122667 13.482667 30.122666 30.101333V150.613333a30.122667 30.122667 0 0 1-60.245333 0V90.346667c0-16.64 13.482667-30.101333 30.122667-30.101334z m180.693333 0c16.64 0 30.122667 13.482667 30.122667 30.101333V150.613333a30.122667 30.122667 0 0 1-60.224 0V90.346667c0-16.64 13.482667-30.101333 30.122666-30.101334z m180.714667 0c16.64 0 30.122667 13.482667 30.122666 30.101333V150.613333a30.122667 30.122667 0 0 1-60.224 0V90.346667c0-16.64 13.482667-30.101333 30.101334-30.101334zM161.706667 301.184a41.216 41.216 0 0 0-41.216 41.216v214.784c0 141.376 114.624 256 256 256h120.469333c141.397333 0 256-114.624 256-256V342.4a41.216 41.216 0 0 0-41.216-41.216H161.706667z m741.845333 188.224v-86.784a11.093333 11.093333 0 0 0-11.093333-11.093333h-79.253334v195.477333a97.898667 97.898667 0 0 0 90.346667-97.6z" p-id="14480"></path></svg>
    #   """

    #   IO.inspect(Sanitizer.sanitize(html), label: "hehe")
    #   # assert Sanitizer.sanitize(html) == "This is <i>text</i>"
    # end
    @tag :wip2
    test "todo" do
      #   IO.inspect(converted, label: "haha")
      converted = Parser.convert_to_html(@real_editor_data)
      #   blocks = converted["blocks"]
      IO.inspect(converted, label: "converted ")
      #   assert not Enum.empty?(converted["blocks"])
    end
  end
end
