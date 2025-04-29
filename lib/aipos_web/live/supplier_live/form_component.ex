defmodule AiposWeb.SupplierLive.FormComponent do
  use AiposWeb, :live_component

  alias Aipos.Suppliers

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full mx-auto">
      <div class="p-4 border-b border-gray-200">
        <h3 class="text-lg font-medium text-gray-900">{@title}</h3>
        <p class="mt-1 text-sm text-gray-500">Enter the supplier's information below.</p>
      </div>

      <.form
        for={@form}
        id="supplier-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="p-4 space-y-4">
          <div>
            <.input
              field={@form[:name]}
              type="text"
              label="Supplier Name"
              placeholder="e.g. Fresh Harvest Supplies"
              required
              class="block w-full border rounded-md shadow-sm py-2 px-3"
            />
          </div>

          <div>
            <.input
              field={@form[:contact_name]}
              type="text"
              label="Contact Person"
              placeholder="Full name of contact person"
              class="block w-full border rounded-md shadow-sm py-2 px-3"
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <.input
                field={@form[:phone]}
                type="text"
                label="Phone Number"
                placeholder="+254 7XX XXX XXX"
                class="block w-full border rounded-md shadow-sm py-2 px-3"
              />
            </div>
            <div>
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                placeholder="contact@example.com"
                class="block w-full border rounded-md shadow-sm py-2 px-3"
              />
            </div>
          </div>

          <div>
            <.input
              field={@form[:address]}
              type="textarea"
              label="Address"
              placeholder="Physical address of supplier"
              rows="2"
              class="block w-full border rounded-md shadow-sm py-2 px-3"
            />
          </div>

          <div>
            <.input
              field={@form[:payment_terms]}
              type="select"
              label="Payment Terms"
              prompt="Select payment terms"
              options={[
                {"Cash on Delivery", "Cash on Delivery"},
                {"Advance Payment", "Advance Payment"}
              ]}
              class="block w-full border rounded-md shadow-sm py-2 px-3"
            />
          </div>

          <div>
            <.input
              field={@form[:status]}
              type="select"
              label="Status"
              options={[{"Active", "active"}, {"Inactive", "inactive"}]}
              value={@form[:status].value || "active"}
              class="block w-full border rounded-md shadow-sm py-2 px-3"
            />
          </div>
        </div>

        <div class="p-4 border-t border-gray-200 flex justify-end space-x-3">
          <.link
            patch={@patch}
            class="px-4 py-2 border rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            Cancel
          </.link>
          <.button
            type="submit"
            class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
            phx-disable-with="Saving..."
          >
            Save Supplier
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{supplier: supplier} = assigns, socket) do
    changeset = Suppliers.change_supplier(supplier)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"supplier" => supplier_params}, socket) do
    changeset =
      socket.assigns.supplier
      |> Suppliers.change_supplier(supplier_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"supplier" => supplier_params}, socket) do
    # Add organization_id to the supplier params
    supplier_params =
      Map.put(
        supplier_params,
        "organization_id",
        socket.assigns.current_user.organization_id
      )

    save_supplier(socket, socket.assigns.action, supplier_params)
  end

  defp save_supplier(socket, :edit, supplier_params) do
    case Suppliers.update_supplier(socket.assigns.supplier, supplier_params) do
      {:ok, supplier} ->
        notify_parent({:saved, supplier})

        {:noreply,
         socket
         |> put_flash(:info, "Supplier updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_supplier(socket, :new, supplier_params) do
    case Suppliers.create_supplier(supplier_params) do
      {:ok, supplier} ->
        notify_parent({:saved, supplier})

        {:noreply,
         socket
         |> put_flash(:info, "Supplier created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
