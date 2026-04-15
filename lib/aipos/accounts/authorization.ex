defmodule Aipos.Accounts.Authorization do
  @moduledoc """
  Role-based access control helpers.
  """

  alias Aipos.Repo
  alias Aipos.Accounts.User

  @doc """
  Returns true if the user has the given permission name.
  Accepts either a preloaded user (with role_ref.permissions) or loads it.
  System_admin users bypass all permission checks.
  """
  def has_permission?(%User{} = user, permission_name) do
    user = ensure_role_loaded(user)

    cond do
      is_nil(user.role_ref) ->
        # Fall back to legacy role string
        legacy_has_permission?(user.role, permission_name)

      user.role_ref.name == "system_admin" ->
        true

      true ->
        Enum.any?(user.role_ref.permissions, fn p -> p.name == permission_name end)
    end
  end

  def has_permission?(nil, _), do: false

  @doc """
  Checks if user has any of the given permissions.
  """
  def has_any_permission?(%User{} = user, permission_names) when is_list(permission_names) do
    Enum.any?(permission_names, &has_permission?(user, &1))
  end

  @doc """
  Returns the role name for a user.
  """
  def role_name(%User{role_ref: %{name: name}}), do: name
  def role_name(%User{role: role}), do: role
  def role_name(_), do: "unknown"

  defp ensure_role_loaded(%User{role_ref: %Aipos.Accounts.Role{}} = user), do: user
  defp ensure_role_loaded(%User{role_id: nil} = user), do: user
  defp ensure_role_loaded(%User{} = user) do
    Repo.preload(user, role_ref: :permissions)
  end

  # Legacy fallback for users that still have string role without role_id
  defp legacy_has_permission?("admin", _), do: true
  defp legacy_has_permission?("system_admin", _), do: true
  defp legacy_has_permission?("org_admin", perm) do
    org_admin_permissions = [
      "dashboard:view", "sales:view", "sales:create",
      "products:view", "products:manage",
      "customers:view", "customers:manage",
      "suppliers:view", "suppliers:manage",
      "registers:view", "registers:manage",
      "users:view", "users:manage",
      "analytics:view", "organizations:manage",
      "receipt_settings:manage"
    ]
    perm in org_admin_permissions
  end
  defp legacy_has_permission?("cashier", perm) do
    cashier_permissions = [
      "dashboard:view", "sales:view", "sales:create",
      "products:view", "customers:view", "registers:view"
    ]
    perm in cashier_permissions
  end
  defp legacy_has_permission?("staff", perm) do
    cashier_permissions = [
      "dashboard:view", "sales:view", "sales:create",
      "products:view", "customers:view", "registers:view"
    ]
    perm in cashier_permissions
  end
  defp legacy_has_permission?(_, _), do: false
end
