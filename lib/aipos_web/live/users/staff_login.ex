defmodule AiposWeb.StaffLogin do
  use AiposWeb, :live_view
  alias Aipos.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Staff Login")
      |> assign(:current_organization, nil)
      |> assign(:form, to_form(%{"staff_id" => ""}))
      |> assign(:error_message, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("login", %{"staff_id" => staff_id}, socket) do
    case Accounts.get_user_by_staff_id(staff_id) do
      nil ->
        {:noreply,
         socket
         |> assign(:error_message, "Invalid Staff ID")
         |> assign(:form, to_form(%{"staff_id" => staff_id}))}

      user ->
        if user.active do
          {:ok, _updated_user} = Accounts.update_last_login(user)

          {:noreply,
           socket
           |> put_flash(:info, "Welcome back, #{user.name}!")
           |> redirect(to: ~p"/dashboard")}
        else
          {:noreply,
           socket
           |> assign(:error_message, "Your account is inactive. Please contact an administrator.")
           |> assign(:form, to_form(%{"staff_id" => staff_id}))}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-gray-100 items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Staff Login
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Enter your staff ID to continue
          </p>
        </div>

        <.form for={@form} phx-submit="login" class="mt-8 space-y-6">
          <div class="rounded-md shadow-sm">
            <div>
              <label for="staff_id" class="sr-only">Staff ID</label>
              <input
                id="staff_id"
                name="staff_id"
                type="text"
                required
                class="appearance-none rounded-md relative block w-full px-3 py-3 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-lg text-center"
                placeholder="Enter 6-digit Staff ID"
                value={@form.params["staff_id"]}
                autofocus
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              class="group relative w-full flex justify-center py-3 px-4 border border-transparent text-lg font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <span class="absolute left-0 inset-y-0 flex items-center pl-3">
                <Heroicons.icon name="key" class="h-5 w-5 text-blue-500 group-hover:text-blue-400" />
              </span>
              Start Shift
            </button>
          </div>

          <div class="text-center">
            <.link navigate={~p"/users/log_in"} class="text-sm text-blue-600 hover:text-blue-500">
              Admin Login
            </.link>
          </div>

          <%= if @error_message do %>
            <div class="rounded-md bg-red-50 p-4 mt-4">
              <div class="flex">
                <div class="flex-shrink-0">
                  <Heroicons.icon name="exclamation-circle" class="h-5 w-5 text-red-400" />
                </div>
                <div class="ml-3">
                  <h3 class="text-sm font-medium text-red-800">
                    {@error_message}
                  </h3>
                </div>
              </div>
            </div>
          <% end %>
        </.form>
      </div>
    </div>
    """
  end
end
