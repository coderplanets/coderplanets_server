defmodule GroupherServer.Test.Helper.Converter.MdToEditor do
  @moduledoc """
  parse markdown string to editorjs's json format
  """
  use GroupherServerWeb.ConnCase, async: true

  alias Helper.Converter.MdToEditor, as: Converter
  alias Helper.Converter.EditorToHTML
  alias Helper.Converter.EditorToHTML.Class

  @root_class Class.article()
  # alias Helper.Converter.HtmlSanitizer, as: Sanitizer

  describe "[basic md test]" do
    # test "basic markdown ast parser should work" do
    #   markdown = """
    #   #  header one

    #   header one paragraph

    #   ## header two

    #   header two paragraph

    #   ### header three

    #   header three paragraph

    #   --     -> invalid spliter

    #   valid spliter
    #   -
    #   valid soliter
    #   ---
    #   valid soliter
    #   ----

    #   this is a paragraph with **bold-text** and _intalic-text_ and [inline-link](https://cps.fun)

    #   [block-link](https://cps.fun)

    #   this is a paragraph with `inline-code-string` in it

    #   - this is ul list item 1
    #   - this is ul list item 2
    #   - this is ul list item 3

    #   1. this is ol list item 1
    #   2. this is ol list item 2
    #   3. this is ol list item 3

    #   - [x] this is *checklist* item true
    #   - [ ] this is checklist item false

    #   > this is *quote* texts

    #   ![image](https://example/example.png)
    #   """

    #   # IO.inspect(Converter.parse(markdown), label: "after parse")

    #   assert Converter.parse(markdown) == [
    #            %{data: %{level: 1, text: "header one"}, type: "header"},
    #            %{data: %{text: "header one paragraph"}, type: "paragraph"},
    #            %{data: %{level: 2, text: "header two"}, type: "header"},
    #            %{data: %{text: "header two paragraph"}, type: "paragraph"},
    #            %{data: %{level: 3, text: "header three"}, type: "header"},
    #            %{data: %{text: "header three paragraph"}, type: "paragraph"},
    #            %{data: %{text: "--     -> invalid spliter"}, type: "paragraph"},
    #            %{data: %{level: 2, text: "valid spliter"}, type: "header"},
    #            %{data: %{text: "valid soliter"}, type: "paragraph"},
    #            %{data: %{}, type: "delimiter"},
    #            %{data: %{text: "valid soliter"}, type: "paragraph"},
    #            %{data: %{}, type: "delimiter"},
    #            %{
    #              data: %{
    #                text:
    #                  "this is a paragraph with <b>bold-text</b> and <i>intalic-text</i> and <a href=\"https://cps.fun\">inline-link</a>"
    #              },
    #              type: "paragraph"
    #            },
    #            %{
    #              data: %{text: "<a href=\"https://cps.fun\">block-link</a>"},
    #              type: "paragraph"
    #            },
    #            %{
    #              data: %{
    #                text:
    #                  "this is a paragraph with <code class=\"inline-code\">inline-code-string</code> in it"
    #              },
    #              type: "paragraph"
    #            },
    #            %{
    #              data: %{
    #                items: [
    #                  "this is ul list item 1",
    #                  "this is ul list item 2",
    #                  "this is ul list item 3"
    #                ],
    #                style: "unordered"
    #              },
    #              type: "list"
    #            },
    #            %{
    #              data: %{
    #                items: [
    #                  "this is ol list item 1",
    #                  "this is ol list item 2",
    #                  "this is ol list item 3"
    #                ],
    #                style: "ordered"
    #              },
    #              type: "list"
    #            },
    #            %{
    #              data: %{
    #                items: [
    #                  %{"checked" => true, "text" => "this is <i>checklist</i> item true"},
    #                  %{"checked" => false, "text" => "this is checklist item false"}
    #                ]
    #              },
    #              type: "checklist"
    #            },
    #            %{data: %{text: "this is <i>quote</i> texts"}, type: "quote"},
    #            %{
    #              data: %{
    #                caption: "",
    #                file: %{url: "https://example/example.png"},
    #                stretched: false,
    #                withBackground: false,
    #                withBorder: false
    #              },
    #              type: "image"
    #            }
    #          ]
    # end

    # test "compose multi inline style in list-item should work" do
    #   markdown = """
    #   - this is ul **list** item 1
    #   - this is ul _list_ item 2
    #   - this is ul _**`list`**_ item 3
    #   """

    #   assert Converter.parse(markdown) == [
    #            %{
    #              data: %{
    #                items: [
    #                  "this is ul <b>list</b> item 1",
    #                  "this is ul <i>list</i> item 2",
    #                  "this is ul <i><b><code class=\"inline-code\">list</code></b></i> item 3"
    #                ],
    #                style: "unordered"
    #              },
    #              type: "list"
    #            }
    #          ]
    # end

    test "complex nested markdown rules should not raise error" do
      markdown = """
      this is a paragraph with **_`inline-code-string`*__* in it
      """

      assert Converter.parse(markdown) == [
               %{
                 data: %{
                   text:
                     "this is a paragraph with <i><code class=\"inline-code\">inline-code-string</code></i>__* in it"
                 },
                 type: "paragraph"
               }
             ]

      markdown = """
      this is a paragraph with __**`inline-code-string`*_* in it
      """

      assert Converter.parse(markdown) == [
               %{
                 data: %{
                   text:
                     "this is a paragraph with <i><i><code class=\"inline-code\">inline-code-string</code></i></i>* in it"
                 },
                 type: "paragraph"
               }
             ]
    end

    test "nested inline code should parse right" do
      markdown = """
      this is a paragraph with **`inline-code-string`** in it
      """

      assert Converter.parse(markdown) == [
               %{
                 data: %{
                   text:
                     "this is a paragraph with <b><code class=\"inline-code\">inline-code-string</code></b> in it"
                 },
                 type: "paragraph"
               }
             ]

      markdown = """
      this is a paragraph with **_`inline-code-string`_** in it
      """

      assert Converter.parse(markdown) == [
               %{
                 data: %{
                   text:
                     "this is a paragraph with <b><i><code class=\"inline-code\">inline-code-string</code></i></b> in it"
                 },
                 type: "paragraph"
               }
             ]

      markdown = """
      this is a paragraph with _**`inline-code-string`**_ in it
      """

      assert Converter.parse(markdown) == [
               %{
                 data: %{
                   text:
                     "this is a paragraph with <i><b><code class=\"inline-code\">inline-code-string</code></b></i> in it"
                 },
                 type: "paragraph"
               }
             ]
    end

    # TODO: inline code parse
    test "complex ast parser should work" do
      markdown = """

      ## hello

      this is a basic *markdown* text

      ### ~~delete me~~

      ### _~~italic me~~_

      My `in-line-code-content` is **best**
      """

      editor_blocks = Converter.parse(markdown)

      {:ok, html} = EditorToHTML.to_html(editor_blocks)

      assert html |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))
      assert html |> String.contains?(~s(<h2 id="block-))
      assert html |> String.contains?(~s(<h3 id="block-))
      assert html |> String.contains?(~s(<i>italic me</i>))
      assert html |> String.contains?(~s(<p id="block-))
      assert html |> String.contains?(~s(<b>best</b>))
    end
  end
end
