defmodule AiposWeb.OrganizationLive.Create do
  use AiposWeb, :live_view

  alias Aipos.Organizations
  alias Aipos.Organizations.Organization
  alias Aipos.Accounts
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    changeset = Organizations.change_organization(%Organization{})

    socket =
      socket
      |> assign(:uploaded_files, [])
      |> allow_upload(:logo,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000,
        progress: &handle_progress/3
      )
      |> assign(:changeset, changeset)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"organization" => organization_params}, socket) do
    changeset =
      %Organization{}
      |> Organizations.change_organization(organization_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"organization" => organization_params}, socket) do
    user_id = socket.assigns.current_user.id

    Logger.info("Starting organization creation with params: #{inspect(organization_params)}")

    uploaded_files =
      consume_uploaded_entries(socket, :logo, fn %{path: path}, entry ->
        uploads_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(uploads_dir)

        filename = "#{:rand.uniform(100_000)}_#{Path.basename(entry.client_name)}"
        dest = Path.join(uploads_dir, filename)

        File.cp!(path, dest)

        Logger.info("Saved logo to: #{dest}")

        {:ok, "/uploads/#{filename}"}
      end)

    organization_params =
      if uploaded_files != [] do
        organization_params
        |> Map.put("logo", List.first(uploaded_files))
        |> Map.put("created_by_id", user_id)
      else
        organization_params
        |> Map.put("created_by_id", user_id)
      end

    Logger.info("Creating organization with final params: #{inspect(organization_params)}")

    case Organizations.create_organization(organization_params) do
      {:ok, organization} ->
        Logger.info("Organization created successfully: #{inspect(organization)}")

        case Accounts.update_user_organization(socket.assigns.current_user, organization.id) do
          {:ok, _user} ->
            {:noreply,
             socket
             |> put_flash(:info, "Organization created successfully!")
             |> redirect(to: ~p"/dashboard")}

          {:error, changeset} ->
            Logger.error("Failed to associate user with organization: #{inspect(changeset)}")

            {:noreply,
             socket
             |> put_flash(:error, "Failed to associate user with organization. Please try again.")
             |> assign(:form, to_form(Organizations.change_organization(%Organization{})))}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Failed to create organization: #{inspect(changeset)}")

        {:noreply,
         socket
         |> put_flash(:error, "Error creating organization. Please check the form.")
         |> assign(:form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :logo, ref)}
  end

  defp handle_progress(:logo, entry, socket) do
    if entry.done? do
      Logger.info("Logo upload completed: #{entry.client_name}")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl py-8">
      <div class="bg-white shadow-lg rounded-lg overflow-hidden">
        <div class="bg-gradient-to-r from-blue-600 to-indigo-800 px-6 py-10 text-white">
          <h1 class="text-3xl font-bold">Create Your Organization</h1>
          <p class="mt-2 text-blue-100">
            Set up your supermarket profile to start using our AI-powered POS system
          </p>
        </div>

        <div class="p-6">
          <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
            <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
              <div class="col-span-2">
                <.input
                  field={@form[:name]}
                  type="text"
                  label="Organization Name"
                  placeholder="Enter your business name"
                  required
                />
              </div>

              <div>
                <.input
                  field={@form[:phone]}
                  type="text"
                  label="Phone Number"
                  placeholder="e.g. (123) 456-7890"
                />
              </div>

              <div>
                <.input
                  field={@form[:email]}
                  type="email"
                  label="Business Email"
                  placeholder="contact@yourbusiness.com"
                />
              </div>

              <div class="col-span-2">
                <.input
                  field={@form[:address]}
                  type="text"
                  label="Address"
                  placeholder="Street Address"
                />
              </div>

              <div class="col-span-2 space-y-4">
                <label class="block text-sm font-medium text-gray-700">
                  Organization Logo (Optional)
                </label>

                <.live_file_input
                  upload={@uploads.logo}
                  class="block w-full text-sm text-gray-500
                  file:mr-4 file:py-2 file:px-4
                  file:rounded-md file:border-0
                  file:text-sm file:font-semibold
                  file:bg-blue-50 file:text-blue-700
                  hover:file:bg-blue-100"
                />

                <%= if @uploads.logo.entries != [] do %>
                  <%= for entry <- @uploads.logo.entries do %>
                    <div class="flex items-center justify-between mt-2 p-2 bg-blue-50 rounded">
                      <div class="flex items-center">
                        <div class="mr-3">
                          <.live_img_preview entry={entry} class="h-12 w-12 object-cover rounded" />
                        </div>
                        <div>
                          <p class="text-sm font-medium text-gray-900">{entry.client_name}</p>
                          <p class="text-xs text-gray-500">{trunc(entry.client_size / 1_000)} KB</p>
                        </div>
                      </div>
                      <button
                        type="button"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        class="text-xs text-red-500"
                      >
                        Cancel
                      </button>
                    </div>

                    <%= if entry.progress > 0 and entry.progress < 100 do %>
                      <div class="w-full bg-gray-200 rounded-full h-2.5 mt-1">
                        <div
                          class="bg-blue-600 h-2.5 rounded-full"
                          style={"width: #{entry.progress}%"}
                        >
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                <% end %>

                <%= for err <- @uploads.logo.errors do %>
                  <div class="text-sm text-red-500 mt-1">
                    <p>{error_to_string(err)}</p>
                  </div>
                <% end %>
              </div>

              <div class="col-span-2">
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label="Description"
                  placeholder="Tell us about your business"
                />
              </div>
            </div>

            <div class="flex items-center justify-end space-x-3 pt-6 border-t border-gray-200">
              <.link navigate={~p"/users/log_in"} class="text-gray-600 hover:text-gray-900">
                Cancel
              </.link>
              <.button
                phx-disable-with="Creating..."
                class="px-6 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-colors"
              >
                Create Organization
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp error_to_string({:too_large, _}), do: "File is too large (max 5MB)"
  defp error_to_string({:too_many_files, _}), do: "You can upload only one logo"
  defp error_to_string({:not_accepted, _}), do: "Invalid file type (allowed: .jpg, .jpeg, .png)"
  defp error_to_string(_), do: "Invalid file"
end
