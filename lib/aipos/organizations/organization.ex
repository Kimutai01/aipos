defmodule Aipos.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :address, :string
    field :email, :string
    field :logo, :string
    field :name, :string
    field :phone, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :address, :phone, :email, :logo])
    |> validate_required([:name, :address, :phone, :email, :logo])
  end
end
