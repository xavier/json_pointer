defmodule JSONPointerTest do
  use ExUnit.Case

  doctest JSONPointer

  setup do

    # Taken from RFC 6901
    # https://tools.ietf.org/html/rfc6901
    rfc_document = %{
      "foo"  => ["bar", "baz"],
      ""     => 0,
      "a/b"  => 1,
      "c%d"  => 2,
      "e^f"  => 3,
      "g|h"  => 4,
      "i\\j" => 5,
      "k\"l" => 6,
      " "    => 7,
      "m~n"  => 8
    }

    # Some document with complex nesting
    document = %{
      "a" => %{
        "x" => %{
          "a" => 1,
          "b" => 2,
        },
        "y" => [
          %{"a" => 11},
          %{"b" => 22},
          nil,
        ]
      },
      "b" => nil,
      "c" => [111, 222, 333]
    }

    {:ok, %{rfc_document: rfc_document, document: document}}
  end

  #
  # Escaping
  #

  test "escape" do
    assert "escaped"       == JSONPointer.escape("escaped")
    assert "esc~0aped"     == JSONPointer.escape("esc~aped")
    assert "~1esc~0aped~1" == JSONPointer.escape("/esc~aped/")
  end

  test "unescape" do
    assert "escaped"    == JSONPointer.unescape("escaped")
    assert "esc~aped"   == JSONPointer.unescape("esc~0aped")
    assert "/esc~aped/" == JSONPointer.unescape("~1esc~0aped~1")
  end

  #
  # RFC-6901 test suite
  #

  test "whole document", %{rfc_document: rfc_document} do
    assert {:ok, rfc_document} == JSONPointer.resolve(rfc_document, "")
  end

  test "simple token", %{rfc_document: rfc_document} do
    assert {:ok, rfc_document["foo"]} == JSONPointer.resolve(rfc_document, "/foo")
  end

  test "array indexing", %{rfc_document: rfc_document} do
    assert {:ok, "bar"} == JSONPointer.resolve(rfc_document, "/foo/0")
    assert {:ok, "baz"} == JSONPointer.resolve(rfc_document, "/foo/1")
  end

  test "forward slash", %{rfc_document: rfc_document} do
    assert {:ok, 0} == JSONPointer.resolve(rfc_document, "/")
  end

  test "escaped forward slash", %{rfc_document: rfc_document} do
    assert {:ok, 1} == JSONPointer.resolve(rfc_document, "/a~1b")
  end

  test "percentage sign", %{rfc_document: rfc_document} do
    assert {:ok, 2} == JSONPointer.resolve(rfc_document, "/c%d")
  end

  test "caret", %{rfc_document: rfc_document} do
    assert {:ok, 3} == JSONPointer.resolve(rfc_document, "/e^f")
  end

  test "pipe", %{rfc_document: rfc_document} do
    assert {:ok, 4} == JSONPointer.resolve(rfc_document, "/g|h")
  end

  test "backslash", %{rfc_document: rfc_document} do
    assert {:ok, 5} == JSONPointer.resolve(rfc_document, "/i\\j")
  end

  test "double quote", %{rfc_document: rfc_document} do
    assert {:ok, 6} == JSONPointer.resolve(rfc_document, "/k\"l")
  end

  test "space", %{rfc_document: rfc_document} do
    assert {:ok, 7} == JSONPointer.resolve(rfc_document, "/ ")
  end

  test "escaped tilde", %{rfc_document: rfc_document} do
    assert {:ok, 8} == JSONPointer.resolve(rfc_document, "/m~0n")
  end

  #
  # Complex document handling and edge cases
  #

  test "complex nesting", %{document: document} do
    assert {:ok, nil} == JSONPointer.resolve(document, "/b")
    assert {:ok, 1} == JSONPointer.resolve(document, "/a/x/a")
    assert {:ok, 22} == JSONPointer.resolve(document, "/a/y/1/b")
  end

  test "empty document" do
    assert {:error, "reference token not found: \"a\""} == JSONPointer.resolve(%{}, "/a/b/c")
  end

  test "index out of bounds", %{document: document} do
    assert {:error, "index 99 out of bounds in [111, 222, 333]"} == JSONPointer.resolve(document, "/c/99")
  end

  test "index on nil", %{document: document} do
    assert {:error, "cannot find index 99 on nil"} == JSONPointer.resolve(document, "/b/99")
  end

  test "nil traversal", %{document: document} do
    assert {:error, "reference token not found: \"bogus\""} == JSONPointer.resolve(document, "/b/bogus/z")
  end

  test "nil traversal in array", %{document: document} do
    assert {:error, "reference token not found: \"bogus\""} == JSONPointer.resolve(document, "/a/y/2/bogus/z")
  end

  test "index with leading zeroes", %{document: document} do
    assert {:error, "index with leading zeros not allowed: \"01\""} == JSONPointer.resolve(document, "/c/01")
  end

  test "non numeric array index", %{document: document} do
    assert {:error, "invalid array index: \"abc\""} == JSONPointer.resolve(document, "/c/abc")
  end

  #
  # Invalid expressions
  #

  test "no leading slash" do
    expected = {:error, "must contain zero or more reference token, each prefixed with \"/\""}
    assert expected == JSONPointer.resolve(%{}, "bogus")
  end

  #
  # Exception
  #

  test "resolve with exception", %{document: document} do
    assert 22 == JSONPointer.resolve!(document, "/a/y/1/b")
    assert_raise ArgumentError, fn ->
      JSONPointer.resolve!(document, "bogus query")
    end
  end

end
