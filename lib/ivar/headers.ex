defmodule Ivar.Headers do
  def put(req, []), do: req
  def put(req, header) when is_tuple(header),
    do: put(req, [header])
  def put(req, headers) do
    req
    |> Map.get(:headers, %{})
    |> put_headers(headers)
    |> put_in_request(req)
  end
  def put(req, key, value),
    do: put(req, [{key, value}])
  
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
  
  defp put_in_request(headers, req),
    do: Map.put(req, :headers, headers)
    
  defp key_to_string(key) when is_atom(key),
    do: Atom.to_string(key)
  defp key_to_string(key) when is_binary(key),
    do: key
end