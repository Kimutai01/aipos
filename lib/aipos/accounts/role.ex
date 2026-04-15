defmodule Aipos.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    field :description, :string

    has_many :role_permissions, Aipos.Accounts.RolePermission
    has_many :permissions, through: [:role_permissions, :permission]
    has_many :users, Aipos.Accounts.User, foreign_key: :role_id

    timestamps(type: :utc_datetime)
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
