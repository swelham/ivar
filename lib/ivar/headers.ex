defmodule Ivar.Headers do
  @moduledoc """
  Ivar.Headers manages the headers stored inside of the headers map
  """
  
  @doc """
  Puts the given `headers` into existing the `request` map
  
  Args
  
  * `request` - the map used to store the map of headers, usually created via `Ivar.new/2`
  * `headers` - the headers to be put into the headers map
  
  Headers
  
  * Key/value tuple - `{:header, "value"}` or `{"header", "value"}`
  * List of Key/value tuple - `[{:header, "value"}]`
  * Keyword list - `[header: "value"]`
  * Map - `%{header: "value"}`
  
  Usage
  
      iex> Ivar.Headers.put(%{}, [accept: "application/json"])
      %{headers: %{"accept" => "application/json"}}
  """
  @spec put(map, {tuple | Keyword.t | map}) :: map
  def put(request, []), do: request
  def put(request, headers) when is_tuple(headers),
    do: put(request, [headers])
  def put(request, headers) do
    request
    |> Map.get(:headers, %{})
    |> put_headers(headers)
    |> put_in_request(request)
  end
  
  @doc """
  Puts the given `value` under `key` into the `request` headers map
  
  Args
  
  * `request` - the map used to store the map of headers, usually created via `Ivar.new/2`
  * `key` - the header name as string or atom (e.g. `:header` or `"header"`)
  * `value` - the header value
  
  Usage
  
      iex> Ivar.Headers.put(%{}, :accept, "application/json")
      %{headers: %{"accept" => "application/json"}}
  """
  @spec put(map, {atom | binary}, binary) :: map
  def put(request, key, value),
    do: put(request, [{key, value}])
  
  defp put_headers(acc, headers) when is_map(headers) do
    headers = Enum.into(headers, [])
    put_headers(acc, headers)
  end
  defp put_headers(acc, []), do: acc
  defp put_headers(acc, [{k, v} | rest]) do
    key = key_to_string(k)
    
    acc
    |> Map.put(key, v)
    |> put_headers(rest)
  end
  
  defp put_in_request(headers, request),
    do: Map.put(request, :headers, headers)
    
  defp key_to_string(key) when is_atom(key),
    do: Atom.to_string(key)
  defp key_to_string(key) when is_binary(key),
    do: key
end