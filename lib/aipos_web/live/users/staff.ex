defmodule AiposWeb.Users.Staff do
  use AiposWeb, :live_view
  alias Aipos.Accounts
  alias Aipos.Accounts.{User, Authorization}

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user && can_manage_staff?(socket.assigns.current_user) do
      current_user = Aipos.Repo.preload(socket.assigns.current_user, role_ref: :permissions)
      organization = get_organization(current_user)

      socket =
        socket
        |> assign(:active_page, "users")
        |> assign(:current_organization, organization)
        |> assign(:current_user, current_user)
        |> assign(:staff_members, list_staff_members(current_user))
        |> assign(:roles, Accounts.list_roles())
        |> assign(:page_title, "Staff Management")
        |> assign(:show_form, false)
        |> assign(:editing_user, nil)
        |> assign(:form, to_form(%{}))
        |> assign(:live_action, :index)

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page")
       |> redirect(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    action = socket.assigns.live_action || :index
    {:noreply, apply_action(socket, action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:editing_user, nil)
    |> assign(:show_form, false)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:editing_user, %User{})
    |> assign(:show_form, true)
    |> assign(:form, to_form(Accounts.change_staff_registration(%User{})))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    staff_member = Accounts.get_user!(id)
    socket
    |> assign(:editing_user, staff_member)
    |> assign(:show_form, true)
    |> assign(:form, to_form(Accounts.change_user(staff_member)))
  end

  defp apply_action(socket, _action, _params) do
    socket |> assign(:editing_user, nil) |> assign(:live_action, :index)
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    staff_member = Accounts.get_user!(String.to_integer(id))

    case Accounts.toggle_user_active(staff_member) do
      {:ok, _} ->
        status = if staff_member.active, do: "deactivated", else: "activated"
        {:noreply,
         socket
         |> put_flash(:info, "User #{status} successfully")
         |> assign(:staff_members, list_staff_members(socket.assigns.current_user))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update user status")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    staff_member = Accounts.get_user!(String.to_integer(id))
    {:ok, _} = Accounts.delete_user(staff_member)

    {:noreply,
     socket
     |> put_flash(:info, "Staff member deleted")
     |> assign(:staff_members, list_staff_members(socket.assigns.current_user))}
  end

  def handle_event("close_form", _, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/manage_users")
     |> assign(:show_form, false)}
  end

  def handle_event("generate_staff_id", _, socket) do
    staff_id = generate_unique_staff_id()
    form =
      socket.assigns.form
      |> Map.put(:source, Map.put(socket.assigns.form.source, :staff_id, staff_id))
      |> Map.put(:params, Map.put(socket.assigns.form.params || %{}, "staff_id", staff_id))
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case socket.assigns.live_action do
      :new -> create_staff_member(socket, user_params)
      :edit -> update_staff_member(socket, socket.assigns.editing_user, user_params)
      _ -> {:noreply, socket}
    end
  end

  defp create_staff_member(socket, params) do
    params = Map.put(params, "organization_id", socket.assigns.current_user.organization_id)

    case Accounts.register_staff_user(params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Staff member created successfully")
         |> push_patch(to: ~p"/manage_users")
         |> assign(:show_form, false)
         |> assign(:staff_members, list_staff_members(socket.assigns.current_user))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp update_staff_member(socket, staff_member, params) do
    case Accounts.update_user(staff_member, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Staff member updated successfully")
         |> push_patch(to: ~p"/manage_users")
         |> assign(:show_form, false)
         |> assign(:staff_members, list_staff_members(socket.assigns.current_user))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp generate_unique_staff_id do
    staff_id = (:rand.uniform(900_000) + 100_000) |> to_string()
    if Accounts.get_user_by_staff_id(staff_id), do: generate_unique_staff_id(), else: staff_id
  end

  defp can_manage_staff?(user) do
    Authorization.has_permission?(user, "users:view") || user.role in ["admin", "system_admin", "org_admin"]
  end

  defp get_organization(user) do
    if user.organization_id do
      Aipos.Organizations.get_organization!(user.organization_id)
    else
      nil
    end
  end

  defp list_staff_members(user) do
    if user.organization_id do
      Accounts.list_users_for_org(user.organization_id)
    else
      Accounts.list_all_users()
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-gray-100">
      <.live_component
        module={AiposWeb.Sidebar}
        id="sidebar"
        current_user={@current_user}
        current_organization={@current_organization}
        active_page={@active_page}
      />

      <div class="flex-1 pl-64 overflow-auto">
        <header class="bg-white shadow">
          <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between">
              <h1 class="text-xl font-bold tracking-tight text-gray-900">Staff Management</h1>
              <.link
                patch={~p"/users/staff/new"}
                class="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
              >
                <Heroicons.icon name="plus" class="h-4 w-4 mr-1" /> Add Staff Member
              </.link>
            </div>
          </div>
        </header>

        <main class="mx-auto max-w-7xl py-6 px-4 sm:px-6 lg:px-8">
          <div class="bg-white shadow rounded-lg overflow-hidden">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Staff ID</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Login</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for staff <- @staff_members do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {staff.staff_id || "—"}
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{staff.name || "—"}</td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{staff.email}</td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <span class={role_badge_class(staff.role)}>
                          {staff.role |> to_string() |> String.replace("_", " ") |> String.split() |> Enum.map(&String.capitalize/1) |> Enum.join(" ")}
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <span class={status_badge_class(staff.active)}>
                          {if staff.active, do: "Active", else: "Inactive"}
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <%= if staff.last_login do %>
                          {Calendar.strftime(staff.last_login, "%d %b %Y, %H:%M")}
                        <% else %>
                          Never
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                        <.link
                          patch={~p"/users/staff/#{staff.id}/edit"}
                          class="text-blue-600 hover:text-blue-900"
                        >
                          Edit
                        </.link>
                        <button
                          phx-click="toggle_active"
                          phx-value-id={staff.id}
                          class={if staff.active, do: "text-orange-600 hover:text-orange-900", else: "text-green-600 hover:text-green-900"}
                        >
                          {if staff.active, do: "Deactivate", else: "Activate"}
                        </button>
                        <button
                          phx-click="delete"
                          phx-value-id={staff.id}
                          data-confirm="Are you sure you want to delete this staff member?"
                          class="text-red-600 hover:text-red-900"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  <% end %>
                  <%= if Enum.empty?(@staff_members) do %>
                    <tr>
                      <td colspan="7" class="px-6 py-8 text-center text-gray-400">No staff members found. Add your first staff member.</td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>

      <%= if @show_form do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity z-50 flex items-center justify-center">
          <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6 mx-4">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-semibold text-gray-900">
                {if @live_action == :new, do: "Add New Staff Member", else: "Edit Staff Member"}
              </h2>
              <button type="button" phx-click="close_form" class="text-gray-400 hover:text-gray-500">
                <Heroicons.icon name="x-mark" class="h-6 w-6" />
              </button>
            </div>

            <.form for={@form} phx-submit="save" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700">Staff ID</label>
                <div class="mt-1 flex rounded-md shadow-sm">
                  <input
                    type="text"
                    name="user[staff_id]"
                    value={@form[:staff_id].value}
                    readonly={@live_action == :edit}
                    class="flex-1 focus:ring-blue-500 focus:border-blue-500 block w-full min-w-0 rounded-l-md sm:text-sm border-gray-300"
                  />
                  <%= if @live_action == :new do %>
                    <button
                      type="button"
                      phx-click="generate_staff_id"
                      class="inline-flex items-center px-3 py-2 border border-l-0 border-gray-300 bg-gray-50 text-gray-500 rounded-r-md hover:bg-gray-100 text-sm"
                    >
                      Generate
                    </button>
                  <% end %>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Name</label>
                <input
                  type="text"
                  name="user[name]"
                  value={@form[:name] && @form[:name].value}
                  class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Email</label>
                <input
                  type="email"
                  name="user[email]"
                  value={@form[:email] && @form[:email].value}
                  class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Role</label>
                <select
                  name="user[role]"
                  class="mt-1 block w-full py-2 px-3 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                >
                  <option value="cashier" selected={@form[:role] && @form[:role].value == "cashier"}>Cashier</option>
                  <option value="org_admin" selected={@form[:role] && @form[:role].value == "org_admin"}>Org Admin</option>
                  <option value="system_admin" selected={@form[:role] && @form[:role].value == "system_admin"}>System Admin</option>
                </select>
              </div>

              <%= if @live_action == :new do %>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Initial Password</label>
                  <input
                    type="password"
                    name="user[password]"
                    class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              <% end %>

              <div>
                <label class="flex items-center">
                  <input
                    type="checkbox"
                    name="user[active]"
                    checked={@form[:active] && @form[:active].value == true}
                    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  />
                  <span class="ml-2 text-sm text-gray-700">Active</span>
                </label>
              </div>

              <div class="flex justify-end pt-4 space-x-2">
                <button
                  type="button"
                  phx-click="close_form"
                  class="bg-white py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                >
                  {if @live_action == :new, do: "Create", else: "Update"}
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp role_badge_class("system_admin"),
    do: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800"
  defp role_badge_class("org_admin"),
    do: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-purple-100 text-purple-800"
  defp role_badge_class("admin"),
    do: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-purple-100 text-purple-800"
  defp role_badge_class("cashier"),
    do: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800"
  defp role_badge_class(_),
    do: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800"

  defp status_badge_class(true),
    do: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800"
  defp status_badge_class(false),
    do: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800"
end
