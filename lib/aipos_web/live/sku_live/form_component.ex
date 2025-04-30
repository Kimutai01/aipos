defmodule AiposWeb.ProductSkuLive.FormComponent do
  use AiposWeb, :live_component

  alias Aipos.Products
  alias Aipos.ProductSkus

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:remove_image, false)
     |> assign(:cards, Aipos.Cards.list_cards())
     |> allow_upload(:sku_image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 5_000_000,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def update(%{product_sku: product_sku} = assigns, socket) do
    changeset = ProductSkus.change_product_sku(product_sku)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"product_sku" => product_sku_params}, socket) do
    changeset =
      socket.assigns.product_sku
      |> ProductSkus.change_product_sku(product_sku_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :sku_image, ref)}
  end

  def handle_event("remove-image", _, socket) do
    {:noreply, assign(socket, :remove_image, true)}
  end

  def handle_event("keep-image", _, socket) do
    {:noreply, assign(socket, :remove_image, false)}
  end

  def handle_event("save", %{"product_sku" => product_sku_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :sku_image, fn %{path: path}, entry ->
        uploads_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(uploads_dir)

        filename = "sku_#{:rand.uniform(100_000)}_#{Path.basename(entry.client_name)}"
        dest = Path.join(uploads_dir, filename)

        File.cp!(path, dest)

        {:ok, AiposWeb.Endpoint.static_path("/uploads/#{filename}")}
      end)

    # Update params with image path based on different conditions
    product_sku_params =
      cond do
        # If user has chosen to remove the image
        socket.assigns.remove_image ->
          Map.put(product_sku_params, "image", nil)

        # If user has uploaded a new image
        uploaded_files != [] ->
          Map.put(product_sku_params, "image", List.first(uploaded_files))

        # Otherwise keep existing image (if any)
        true ->
          product_sku_params
      end

    # Set organization_id and user_id
    product_sku_params =
      product_sku_params
      |> Map.put("organization_id", socket.assigns.current_user.organization_id)
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("product_id", socket.assigns.product.id)

    save_product_sku(socket, socket.assigns.action, product_sku_params)
  end

  defp handle_progress(:sku_image, entry, socket) do
    if entry.done? do
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp save_product_sku(socket, :edit, product_sku_params) do
    case ProductSkus.update_product_sku(socket.assigns.product_sku, product_sku_params) do
      {:ok, _product_sku} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product SKU updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:form, to_form(changeset))}
    end
  end

  defp save_product_sku(socket, :new, product_sku_params) do
    case ProductSkus.create_product_sku(product_sku_params) do
      {:ok, _product_sku} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product SKU created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:form, to_form(changeset))}
    end
  end

  defp error_to_string({:too_large, _}), do: "File is too large (max 5MB)"
  defp error_to_string({:too_many_files, _}), do: "You can upload only one image"
  defp error_to_string({:not_accepted, _}), do: "Invalid file type (allowed: .jpg, .jpeg, .png)"
  defp error_to_string(_), do: "Invalid file"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg overflow-hidden max-w-2xl w-full mx-auto">
      <div class="bg-gradient-to-r from-blue-600 to-indigo-800 p-6">
        <h2 class="text-xl font-bold text-white">{@title}</h2>
        <p class="text-blue-100 mt-1 text-sm">
          Enter SKU details below for {@product.name}
        </p>
      </div>

      <div class="p-6">
        <.form
          for={@form}
          id="product-sku-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
            <div class="sm:col-span-3">
              <.input
                field={@form[:name]}
                type="text"
                label="Variant Name"
                required
                placeholder="e.g. 1KG, 2KG, Red, etc."
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:barcode]}
                type="text"
                label="Barcode"
                placeholder="Enter barcode (optional)"
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:price]}
                type="number"
                label="Price"
                required
                step="0.01"
                min="0"
                placeholder="0.00"
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:cost]}
                type="number"
                label="Cost"
                required
                step="0.01"
                min="0"
                placeholder="0.00"
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:stock_quantity]}
                type="number"
                label="Stock Quantity"
                required
                step="1"
                min="0"
                placeholder="0"
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:buffer_level]}
                type="number"
                label="Reorder Level"
                required
                step="1"
                min="0"
                placeholder="10"
              />
            </div>

            <div class="sm:col-span-6">
              <label class="block text-sm font-medium text-gray-700">RFID Card</label>
              <select
                name="product_sku[rfid_tag]"
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                id={@form[:rfid_tag].id}
              >
                <option value="">Select a Card</option>
                <%= for card <- @cards do %>
                  <option value={card.card} selected={@form[:rfid_tag].value == card.card}>
                    {card.card}{if card.device, do: " (#{card.device})"}
                  </option>
                <% end %>
              </select>
              <p class="mt-1 text-xs text-gray-500">
                Link this product to an RFID card for inventory tracking
              </p>

              <%= if @form[:rfid_tag].errors != [] do %>
                <div class="mt-1 text-sm text-red-600">
                  {Enum.map(@form[:rfid_tag].errors, fn {msg, _} -> msg end) |> Enum.join(", ")}
                </div>
              <% end %>
            </div>

            <div class="sm:col-span-6">
              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="Optional description for this variant"
                rows="2"
              />
            </div>

            <div class="sm:col-span-6 space-y-4">
              <label class="block text-sm font-medium text-gray-700">
                SKU Image (Optional)
              </label>

              <%= if Map.get(@product_sku, :image) && !@remove_image do %>
                <div class="mt-2 flex items-center space-x-3">
                  <div class="h-20 w-20 rounded-md overflow-hidden bg-gray-100">
                    <img src={@product_sku.image} alt="SKU Image" class="h-20 w-20 object-cover" />
                  </div>
                  <button
                    type="button"
                    phx-click="remove-image"
                    phx-target={@myself}
                    class="rounded-md border border-rose-300 bg-white py-2 px-3 text-sm font-medium text-rose-700 hover:bg-rose-50"
                  >
                    Remove
                  </button>
                </div>
              <% else %>
                <!-- Show "Keep Image" button if user initially chose to remove an image -->
                <%= if Map.get(@product_sku, :image) && @remove_image do %>
                  <div class="mt-2 flex items-center">
                    <button
                      type="button"
                      phx-click="keep-image"
                      phx-target={@myself}
                      class="rounded-md border border-blue-300 bg-white py-2 px-3 text-sm font-medium text-blue-700 hover:bg-blue-50"
                    >
                      Keep Existing Image
                    </button>
                  </div>
                <% end %>

                <.live_file_input
                  upload={@uploads.sku_image}
                  class="block w-full text-sm text-gray-500
                    file:mr-4 file:py-2 file:px-4
                    file:rounded-md file:border-0
                    file:text-sm file:font-semibold
                    file:bg-blue-50 file:text-blue-700
                    hover:file:bg-blue-100"
                />

                <%= if @uploads.sku_image.entries != [] do %>
                  <%= for entry <- @uploads.sku_image.entries do %>
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
                        phx-target={@myself}
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

                <%= for err <- @uploads.sku_image.errors do %>
                  <div class="text-sm text-red-500 mt-1">
                    <p>{error_to_string(err)}</p>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <div class="flex justify-end space-x-3 pt-5 border-t border-gray-200">
            <.link
              patch={@patch}
              class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Cancel
            </.link>
            <.button type="submit" phx-disable-with="Saving...">
              Save SKU
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
