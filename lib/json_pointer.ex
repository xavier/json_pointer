defmodule JSONPointer do

  @moduledoc """

  Implementation of [RFC 6901](https://tools.ietf.org/html/rfc6901)
  which defines a string syntax for identifying a specific value within a JSON document.

  ## Usage

  *Preleminary note: the actual parsing of the JSON document is outside of the scope of this library,
  feel free to select on the several libraries available.*

  The `resolve/2` and `resolve!/2` functions expect to receive documents in the form of nested maps and lists,
  as produced by most JSON parsers.

      iex> document = %{
      ...>   "key" => "value",
      ...>   "list" => [1, 2, 3],
      ...>   "deeply" => %{"nested" => %{"values" => [%{"x" => 1}, %{"x" => 2}]}}
      ...> }
      iex> JSONPointer.resolve(document, "/key")
      {:ok, "value"}
      iex> JSONPointer.resolve(document, "/list/1")
      {:ok, 2}
      iex> JSONPointer.resolve(document, "/deeply/nested/values/0")
      {:ok, %{"x" => 1}}
      iex> JSONPointer.resolve(document, "/deeply/nested/values/1/x")
      {:ok, 2}
      iex> JSONPointer.resolve(document, "/list/4")
      {:error, "index 4 out of bounds in [1, 2, 3]"}

  """

  @type json_object :: map
  @type json_value :: nil | true | false | list | float | integer | String.t | json_object

  @doc """
  Escapes a string in order to be usable as reference token.

      iex> JSONPointer.escape("/esc~aped")
      "~1esc~0aped"

  """
  @spec escape(String.t) :: String.t
  def escape(string) do
    string
    |> String.replace("~", "~0")
    |> String.replace("/", "~1")
  end

  @doc """
  Unescapes a reference token and returns the original string

      iex> JSONPointer.unescape("~1esc~0aped")
      "/esc~aped"

  """
  @spec unescape(String.t) :: String.t
  def unescape(string) do
    string
    |> String.replace("~1", "/")
    |> String.replace("~0", "~")
  end

  @doc """
  Resolves a JSON Pointer `expr` against the given `document` and
  returns the referenced value.

  Raises an `ArgumentError` exception if an error occurs

      iex> JSONPointer.resolve!(%{"key" => "value"}, "/key")
      "value"
      iex> JSONPointer.resolve!(%{"key" => "value"}, "/bogus")
      ** (ArgumentError) reference token not found: "bogus"

  """
  @spec resolve!(json_object, String.t) :: json_value | no_return
  def resolve!(document, expr) do
    case resolve(document, expr) do
      {:ok, value}
        -> value
      {:error, message}
        -> raise ArgumentError, message
    end
  end

  @doc """
  Resolves a JSON Pointer `expr` against the given `document` and
  returns `{:ok, value}` on success and `{:error, message}` otherwise.

      iex> JSONPointer.resolve(%{"key" => "value"}, "/key")
      {:ok, "value"}
      iex> JSONPointer.resolve(%{"key" => "value"}, "/bogus")
      {:error, "reference token not found: \\"bogus\\""}

  """
  @spec resolve(json_object, String.t) :: {:ok, json_value} | {:error, String.t}
  def resolve(document, ""), do: {:ok, document}
  def resolve(document, _expr = <<"/", expr::binary>>), do: do_resolve(document, String.split(expr, "/"))
  def resolve(_document, _expr), do: {:error, "must contain zero or more reference token, each prefixed with \"/\""}

  #
  # Private interface
  #

  defp do_resolve(document, []),   do: {:ok, document}
  defp do_resolve(document, [token|rest]) do
    token = unescape(token)
    cond do
      is_numeric?(token)
        -> do_resolve_array_index(document, token, rest)
      token
        -> do_resolve_token(document, token, rest)
    end
  end

  defp do_resolve_token(nil, token, _), do: {:error, "reference token not found: #{inspect token}"}
  defp do_resolve_token(document, token, _) when is_list(document), do: {:error, "invalid array index: #{inspect token}"}
  defp do_resolve_token(document, token, rest) do
    case Map.fetch(document, token) do
      :error
        -> {:error, "reference token not found: #{inspect token}"}
      {:ok, value}
        -> do_resolve(value, rest)
    end
  end

  defp do_resolve_array_index(nil, token, _rest), do: {:error, "cannot find index #{token} on nil"}
  defp do_resolve_array_index(_document, index = <<"0", _, _::binary>>, _rest), do: {:error, "index with leading zeros not allowed: #{inspect index}"}
  defp do_resolve_array_index(document, token, rest) do
    index = Integer.parse(token) |> elem(0)
    case Enum.at(document, index, :error) do
      :error
        -> {:error, "index #{index} out of bounds in #{inspect document}"}
      value
        -> do_resolve(value, rest)
    end
  end

  defp is_numeric?(token), do: Regex.match?(~r/\A\d+\Z/, token)

end
