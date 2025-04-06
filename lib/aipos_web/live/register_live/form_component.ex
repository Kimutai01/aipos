defmodule AiposWeb.RegisterLive.FormComponent do
  use AiposWeb, :live_component

  alias Aipos.Registers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage register records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="register-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={[
            {"Available", "available"},
            {"In Use", "in_use"}
          ]}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Register</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{register: register} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Registers.change_register(register))
     end)}
  end

  @impl true
  def handle_event("validate", %{"register" => register_params}, socket) do
    changeset = Registers.change_register(socket.assigns.register, register_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"register" => register_params}, socket) do
    save_register(socket, socket.assigns.action, register_params)
  end

  defp save_register(socket, :edit, register_params) do
    case Registers.update_register(socket.assigns.register, register_params) do
      {:ok, register} ->
        notify_parent({:saved, register})

        {:noreply,
         socket
         |> put_flash(:info, "Register updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_register(socket, :new, register_params) do
    case Registers.create_register(
           register_params
           |> Map.put("organization_id", socket.assigns.current_organization.id)
         ) do
      {:ok, register} ->
        notify_parent({:saved, register})

        {:noreply,
         socket
         |> put_flash(:info, "Register created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:ok, register} ->
        notify_parent({:saved, register})

        {:noreply,
         socket
         |> put_flash(:info, "Register created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
