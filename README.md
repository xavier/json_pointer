# JSON Pointer

An implementation of [RFC 6901](https://tools.ietf.org/html/rfc6901) which defines a string syntax for identifying a specific value within a JSON document.

## Installation

Add a dependency to your project `mix.exs`:

```Elixir

def deps do
  [{:json_pointer, "~> 0.0.1"}]
end

```
## Usage

```Elixir

document = %{
  "key" => "value",
  "list" => [1, 2, 3],
  "deeply" => %{
    "nested" =>
      %{"values" => [
        %{"x" => 1},
        %{"x" => 2}
      ]
    }
  }
}

JSONPointer.resolve(document, "/key")
# => {:ok, "value"}
JSONPointer.resolve(document, "/list/1")
# => {:ok, 2}
JSONPointer.resolve(document, "/deeply/nested/values/0")
# => {:ok, %{"x" => 1}}
JSONPointer.resolve(document, "/deeply/nested/values/1/x")
# => {:ok, 2}
JSONPointer.resolve(document, "/list/4")
# => {:error, "index 4 out of bounds in [1, 2, 3]"}

```

## Dependencies

This library works with deserialized documents and does not include a JSON parser.