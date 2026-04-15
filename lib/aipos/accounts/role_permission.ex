defmodule Aipos.Accounts.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "role_permissions" do
    belongs_to :role, Aipos.Accounts.Role
    belongs_to :permission, Aipos.Accounts.Permission

    timestamps(type: :utc_datetime)
  end

  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role_id, :permission_id])
    |> validate_required([:role_id, :permission_id])
    |> unique_constraint([:role_id, :permission_id])
  end
end
