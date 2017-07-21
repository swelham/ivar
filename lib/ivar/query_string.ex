defmodule Ivar.QueryString do
  @moduledoc """
  `Ivar.QueryString` manages the query string values to be appended to the url
  """

  @doc """
  Puts the given query `params` into the existing `request` map
  
  Args
  
  * `request` - the map used to store the map of query string parameters, usually created via `Ivar.new/2`
  * `params` - the key/value params to put into the query string
  
  Params
  
  * List of Key/value tuple - `[{:key, "value"}, {"q", "ivar"}]`
  * Keyword list - `[key: "value"]`
  * Map - `%{key: "value"} | %{"key" => "value"}`
  
  Usage
  
      iex> Ivar.QueryString.put(%{}, [q: "ivar"])
      %{query: %{"q" => "ivar"}}
  """
  @spec put(map, list | Keyword.t | map) :: map
  def put(request, params) when is_map(params),
    do: put_params(request, params)
  def put(request, params) do
    params = Enum.into(params, %{})
    put_params(request, params)
  end
  
  defp put_params(request, params) do
    params = params
    |> Enum.map(&stringify_key/1)
    |> Enum.into(%{})

    query = request
    |> Map.get(:query, %{})
    |> Map.merge(params)

    Map.put(request, :query, query)
  end

  defp stringify_key({k, v}) when is_atom(k),
    do: {Atom.to_string(k), v}
  defp stringify_key(item), do: item
end
