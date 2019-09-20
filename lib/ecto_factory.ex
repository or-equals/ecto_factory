defmodule EctoFactory do
  import Enum, only: [random: 1]
  import Application, only: [get_env: 2]

  @doc """
  Create a struct of the passed in factory

  After configuring a factory

      config :ecto_factory, factories: [
        user: User,

        user_with_default_username: { User,
          username: "mrmicahcooper"
        }
      ]

  You can build a struct with the attributes from your factory as defaults.

      EctoFactory.build(:user_with_default_username)

      %User{
        age: 124309132# random number
        username: "mrmicahcooper"
      }

  And you can pass in your own attributes of course:


      EctoFactory.build(:user, age: 99, username: "hashrocket")

    %User{
        age: 99,
        username: "hashrocket"
      }

  """
  def build(factory_name, attrs \\ []) do
    {schema, attributes} = build_attrs(factory_name, attrs)
    struct(schema, attributes)
  end

  def build_attrs(factory_name, attributes) do
    {schema, defaults} =
      if function_exported?(factory_name, :__changeset__, 0) do
        {factory_name, []}
      else
        factory(factory_name)
      end

    keys = Keyword.keys(defaults ++ attributes) ++ schema.__schema__(:primary_key)

    attrs =
      schema.__changeset__()
      |> Map.drop(keys)
      |> Enum.map(&cast/1)
      |> Keyword.merge(defaults)
      |> Keyword.merge(attributes)

    {schema, attrs}
  end

  defp factory(factory_name) do
    case get_env(:ecto_factory, :factories)[factory_name] do
      nil -> raise(EctoFactory.MissingFactory, factory_name)
      {schema, defaults} -> {schema, defaults}
      {schema} -> {schema, []}
      schema -> {schema, []}
    end
  end

  defp cast({key, {:assoc, %{cardinality: :many}}}), do: {key, []}
  defp cast({key, {:assoc, %{cardinality: :one}}}), do: {key, nil}
  defp cast({key, data_type}), do: {key, gen(data_type)}

  defp gen(:id), do: random(1..9_999_999)
  defp gen(:binary_id), do: Ecto.UUID.generate()
  defp gen(:integer), do: random(1..9_999_999)
  defp gen(:float), do: (random(99..99999) / random(1..99)) |> Float.round(2)
  defp gen(:decimal), do: gen(:float)
  defp gen(:boolean), do: random([true, false])
  defp gen(:binary), do: Ecto.UUID.generate()
  defp gen({:array, type}), do: 1..random(2..9) |> Enum.map(fn _ -> gen(type) end)
  defp gen(:date), do: Date.utc_today()
  defp gen(:time), do: Time.utc_now()
  defp gen(:time_usec), do: gen(:time)
  defp gen(:naive_datetime), do: NaiveDateTime.utc_now()
  defp gen(:naive_datetime_usec), do: gen(:naive_datetime)
  defp gen(:utc_datetime), do: DateTime.utc_now()
  defp gen(:utc_datetime_usec), do: gen(:utc_datetime)

  defp gen(:string) do
    for(_ <- 1..random(8..20), into: "", do: <<random(?a..?z)>>)
  end

  defp gen(:map), do: gen({:map, :string})

  defp gen({:map, type}) do
    for(key <- gen({:array, :string}), into: %{}, do: {key, gen(type)})
  end

  defp gen(_), do: nil
end
