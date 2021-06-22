defmodule GroupherServer.Test.Helper.UtilsTest do
  use GroupherServerWeb.ConnCase, async: true

  alias GroupherServer.CMS.Model.Post
  alias Helper.Utils

  describe "map atom value up upcase str" do
    test "atom value can be convert to upcase str" do
      map = %{
        color: :green,
        thread: :post,
        other: "hello"
      }

      result = Utils.atom_values_to_upcase(map)

      assert result.color == "GREEN"
      assert result.thread == "POST"
      assert result.other == "hello"
    end
  end

  describe "map keys to string" do
    test "atom keys should covert to string keys on nested map" do
      atom_map = %{
        data: %{
          text: "My in-line-code-content is <b>best</b>"
        },
        type: "paragraph"
      }

      string_map = %{
        "data" => %{
          "text" => "My in-line-code-content is <b>best</b>"
        },
        "type" => "paragraph"
      }

      assert Utils.keys_to_strings(atom_map) == string_map
    end
  end

  describe "map keys to atom" do
    test "string keys should covert to atom keys on nested map" do
      atom_map = %{
        string_array: [
          "line 1",
          "line 2",
          "line 3"
        ],
        blocks: [
          %{
            data: %{
              items: [
                %{
                  checked: true,
                  hideLabel: true,
                  indent: 0,
                  label: "label",
                  labelType: "success",
                  text: "list item"
                }
              ],
              mode: "checklist"
            },
            type: "list"
          }
        ]
      }

      # atoms dynamically and atoms are not
      # garbage-collected. Therefore, string should not be an untrusted value, such as
      # input received from a socket or during a web request. Consider using
      # to_existing_atom/1 instead
      # keys_to_atoms is using to_existing_atom under the hook

      _ = :hideLabel
      _ = :labelType

      string_map = %{
        "string_array" => [
          "line 1",
          "line 2",
          "line 3"
        ],
        "blocks" => [
          %{
            "data" => %{
              "items" => [
                %{
                  "checked" => true,
                  "hideLabel" => true,
                  "indent" => 0,
                  "label" => "label",
                  "labelType" => "success",
                  "text" => "list item"
                }
              ],
              "mode" => "checklist"
            },
            "type" => "list"
          }
        ]
      }

      assert Utils.keys_to_atoms(string_map) == atom_map
    end
  end

  describe "[deep merge]" do
    test "one level of maps without conflict" do
      result = Utils.deep_merge(%{a: 1}, %{b: 2})
      assert result == %{a: 1, b: 2}
    end

    test "two levels of maps without conflict" do
      result = Utils.deep_merge(%{a: %{b: 1}}, %{a: %{c: 3}})
      assert result == %{a: %{b: 1, c: 3}}
    end

    test "three levels of maps without conflict" do
      result = Utils.deep_merge(%{a: %{b: %{c: 1}}}, %{a: %{b: %{d: 2}}})
      assert result == %{a: %{b: %{c: 1, d: 2}}}
    end

    test "non-map value in left" do
      result = Utils.deep_merge(%{a: 1}, %{a: %{b: 2}})
      assert result == %{a: %{b: 2}}
    end

    test "non-map value in right" do
      result = Utils.deep_merge(%{a: %{b: 1}}, %{a: 2})
      assert result == %{a: 2}
    end

    test "non-map value in both" do
      result = Utils.deep_merge(%{a: 1}, %{a: 2})
      assert result == %{a: 2}
    end
  end

  describe "[sub str occurence]" do
    test "normal occurence case" do
      assert 2 == Utils.str_occurence("foo bar foobar", "foo")
      assert 0 == Utils.str_occurence("hello world", "foo")
    end
  end

  describe "[basic compare]" do
    test "large_than work for both number and string" do
      assert true == Utils.large_than(10, 9)
      assert false == Utils.large_than(8, 9)

      assert true == Utils.large_than("lang", 3)
      assert false == Utils.large_than("ok", 3)
    end

    test "large_than equal case" do
      assert true == Utils.large_than(9, 9)
      assert false == Utils.large_than(9, 9, :no_equal)

      assert true == Utils.large_than("lang", 4)
      assert false == Utils.large_than("lang", 4, :no_equal)
    end

    test "less_than work for both number and string" do
      assert false == Utils.less_than(10, 9)
      assert true == Utils.less_than(8, 9)

      assert false == Utils.less_than("lang", 3)
      assert true == Utils.less_than("ok", 3)
    end

    test "less_than equal case" do
      assert true == Utils.less_than(9, 9)
      assert false == Utils.less_than(9, 9, :no_equal)

      assert true == Utils.less_than("lang", 4)
      assert false == Utils.less_than("lang", 4, :no_equal)
    end
  end

  describe "[uid generator]" do
    test "default id should have length of 5" do
      uid_str = Utils.uid()
      assert String.length(uid_str) == 5
    end

    test "should gen uniq id with lengh of 5" do
      uid_str = Utils.uid(:html, "what_ever")
      assert String.length(uid_str) == 5
    end

    test "should never contains number" do
      uid_str = Utils.uid(:html, %{"id" => ""})
      assert String.match?(uid_str, ~r/[0-9]/) == false
    end

    test "exsit id will stay the same" do
      assert "exsit_id" == Utils.uid(:html, %{"id" => "exsit_id"})
    end
  end

  describe "[others]" do
    test "module_to_atom should work" do
      assert :post == Post |> Utils.module_to_atom()
      assert :post == %Post{} |> Utils.module_to_atom()

      # invalid case
      assert nil == "whatever" |> Utils.module_to_atom()
      assert nil == :whatever |> Utils.module_to_atom()
      assert nil == 8848 |> Utils.module_to_atom()
    end
  end
end
