defmodule User do
  use Ecto.Schema
  alias EctoURI

  schema "users" do
    field(:username)
    field(:age, :integer)
    field(:date_of_birth, :date)
    field(:addresses, {:array, :string})
    field(:profile, :map)
    field(:admin, :boolean)
    field(:avatar_url, EctoURI)
  end
end
