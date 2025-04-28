defmodule AiposWeb.CustomerLive.FormComponent do
  use AiposWeb, :live_component

  alias Aipos.Customers

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full mx-auto">
      <div class="p-4 border-b border-gray-200">
        <h3 class="text-lg font-medium text-gray-900">{@title}</h3>
        <p class="mt-1 text-sm text-gray-500">Enter the customer's information below.</p>
      </div>

      <.form
        for={@form}
        id="customer-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="p-4 space-y-4">
          <div>
            <.input
              field={@form[:name]}
              type="text"
              label="Name"
              placeholder="Full name"
              required
              class="mt-1 block w-full border rounded-md shadow-sm py-2 px-3"
            />
          </div>

          <div>
            <.input
              field={@form[:phone]}
              type="text"
              label="Phone"
              placeholder="07XX XXX XXX"
              required
              class="mt-1 block w-full border rounded-md shadow-sm py-2 px-3"
            />
          </div>

          <div>
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              placeholder="customer@example.com"
              class="mt-1 block w-full border rounded-md shadow-sm py-2 px-3"
            />
          </div>

          <div>
            <.input
              field={@form[:address]}
              type="textarea"
              label="Address"
              placeholder="Customer's physical address"
              rows="2"
              class="mt-1 block w-full border rounded-md shadow-sm py-2 px-3"
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
            Save Customer
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{customer: customer} = assigns, socket) do
    changeset = Customers.change_customer(customer)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"customer" => customer_params}, socket) do
    changeset =
      socket.assigns.customer
      |> Customers.change_customer(customer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"customer" => customer_params}, socket) do
    save_customer(socket, socket.assigns.action, customer_params)
  end

  defp save_customer(socket, :edit, customer_params) do
    case Customers.update_customer(socket.assigns.customer, customer_params) do
      {:ok, customer} ->
        notify_parent({:saved, customer})

        {:noreply,
         socket
         |> put_flash(:info, "Customer updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_customer(socket, :new, customer_params) do
    customer_params =
      Map.merge(
        %{
          "loyalty_points" => "0",
          "membership_level" => "Bronze",
          "total_spent" => "0",
          "total_orders" => "0",
          "days_since_last_purchase" => "0"
        },
        customer_params
      )

    case Customers.create_customer(customer_params) do
      {:ok, customer} ->
        notify_parent({:saved, customer})

        {:noreply,
         socket
         |> put_flash(:info, "Customer added successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
