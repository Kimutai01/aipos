defmodule Aipos.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    field :description, :string
    field :category, :string

    has_many :role_permissions, Aipos.Accounts.RolePermission

    timestamps(type: :utc_datetime)
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :description, :category])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
