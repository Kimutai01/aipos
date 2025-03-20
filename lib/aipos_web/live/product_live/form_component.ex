defmodule AiposWeb.ProductLive.FormComponent do
  use AiposWeb, :live_component

  alias Aipos.Products
  alias Aipos.ProductSkus
  alias Aipos.ProductSkus.ProductSku

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:show_sku_form, false)
     |> assign(:skus, [])
     |> assign(:sku_changeset, %ProductSku{} |> ProductSkus.change_product_sku())
     |> assign(:sku_form, to_form(ProductSkus.change_product_sku(%ProductSku{})))
     |> allow_upload(:product_image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:form, fn ->
        to_form(Products.change_product(product))
      end)
      |> assign(:skus, get_product_skus(product))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Products.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("validate_sku", %{"product_sku" => sku_params}, socket) do
    changeset =
      %ProductSku{}
      |> ProductSkus.change_product_sku(sku_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, sku_form: to_form(changeset))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :product_image, ref)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    # Process uploaded image if any
    uploaded_files =
      consume_uploaded_entries(socket, :product_image, fn %{path: path}, entry ->
        # Create uploads directory if it doesn't exist
        uploads_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(uploads_dir)

        # Generate unique filename to prevent overwriting
        extension = Path.extname(entry.client_name)
        filename = "#{:rand.uniform(100_000)}_#{Path.basename(entry.client_name)}"
        dest = Path.join(uploads_dir, filename)

        # Copy file to destination
        File.cp!(path, dest)

        # Return the public path
        {:ok, "/uploads/#{filename}"}
      end)

    # Update params with logo path
    product_params =
      case uploaded_files do
        [image_path | _] -> Map.put(product_params, "image", image_path)
        _ -> product_params
      end

    # Set organization_id
    product_params =
      Map.put(product_params, "organization_id", socket.assigns.current_user.organization_id)

    save_product(socket, socket.assigns.action, product_params)
  end

  def handle_event("show_sku_form", _, socket) do
    {:noreply, assign(socket, show_sku_form: true)}
  end

  def handle_event("hide_sku_form", _, socket) do
    {:noreply, assign(socket, show_sku_form: false)}
  end

  def handle_event("add_sku", %{"product_sku" => sku_params}, socket) do
    # Create a new SKU with a unique ID
    new_sku = %{
      id: System.unique_integer([:positive]),
      name: sku_params["name"],
      description: sku_params["description"],
      barcode: sku_params["barcode"],
      price: sku_params["price"],
      cost: sku_params["cost"],
      stock_quantity: sku_params["stock_quantity"],
      buffer_level: sku_params["buffer_level"]
    }

    # Add the new SKU to the existing list
    skus = [new_sku | socket.assigns.skus]

    # Reset the SKU form and hide it
    {:noreply,
     socket
     |> assign(:skus, skus)
     |> assign(:show_sku_form, false)
     |> assign(:sku_form, to_form(ProductSkus.change_product_sku(%ProductSku{})))}
  end

  def handle_event("remove_sku", %{"id" => id}, socket) do
    # Convert string ID to integer for comparison
    id = String.to_integer(id)
    skus = Enum.reject(socket.assigns.skus, &(&1.id == id))
    {:noreply, assign(socket, :skus, skus)}
  end

  defp save_product(socket, :edit, product_params) do
    case Products.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        # Here you would save the SKUs associated with the product
        # For each SKU in socket.assigns.skus, update it with product.id
        save_product_skus(product.id, socket.assigns.skus)

        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_product(socket, :new, product_params) do
    case Products.create_product(product_params) do
      {:ok, product} ->
        # Here you would save the SKUs associated with the product
        # For each SKU in socket.assigns.skus, save it with product.id
        save_product_skus(product.id, socket.assigns.skus)

        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # Helper function to save SKUs for a product
  defp save_product_skus(product_id, skus) do
    # In a real implementation, you would save each SKU to the database
    # This is a placeholder
    for sku <- skus do
      sku_params = Map.put(sku, :product_id, product_id)
      # ProductSkus.create_product_sku(sku_params)
      # For now, we're just logging
      IO.inspect(sku_params, label: "Saving SKU")
    end
  end

  defp get_product_skus(product) do
    # Placeholder - in a real implementation, you'd query the database
    # for SKUs associated with this product
    []
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg overflow-hidden max-w-2xl w-full mx-auto">
      <div class="bg-gradient-to-r from-blue-600 to-indigo-800 p-6">
        <h2 class="text-xl font-bold text-white">{@title}</h2>
        <p class="text-blue-100 mt-1 text-sm">
          Enter product details below. You can add SKUs after saving the main product.
        </p>
      </div>

      <div class="p-6">
        <.form
          for={@form}
          id="product-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="md:col-span-2">
              <.input
                field={@form[:name]}
                type="text"
                label="Product Name"
                required
                placeholder="Enter product name"
              />
            </div>

            <div class="md:col-span-2">
              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="Enter product description"
                rows={3}
              />
            </div>

            <div>
              <.input
                field={@form[:category_id]}
                type="select"
                label="Category"
                options={category_options()}
              />
            </div>

            <div>
              <.input field={@form[:brand]} type="text" label="Brand" placeholder="Enter brand name" />
            </div>

            <div class="md:col-span-2">
              <label class="block text-sm font-medium text-gray-700 mb-1">Product Image</label>
              <div class="mt-1 border-2 border-dashed border-gray-300 rounded-lg p-6">
                <div class="space-y-2 text-center">
                  <%= if Enum.empty?(@uploads.product_image.entries) do %>
                    <div class="mx-auto h-24 w-24 flex items-center justify-center rounded-full bg-gray-100">
                      <Heroicons.icon name="photo" class="h-12 w-12 text-gray-400" />
                    </div>
                    <div class="flex justify-center text-sm">
                      <label
                        for={@uploads.product_image.ref}
                        class="relative cursor-pointer rounded-md bg-white font-medium text-blue-600 hover:text-blue-500"
                      >
                        <span>Upload a file</span>
                        <.live_file_input upload={@uploads.product_image} class="sr-only" />
                      </label>
                      <p class="pl-1 text-gray-500">or drag and drop</p>
                    </div>
                    <p class="text-xs text-gray-500">PNG, JPG, JPEG up to 5MB</p>
                  <% else %>
                    <%= for entry <- @uploads.product_image.entries do %>
                      <div class="relative mx-auto h-24 w-24">
                        <.live_img_preview
                          entry={entry}
                          class="mx-auto h-24 w-24 rounded-lg object-cover"
                        />
                        <button
                          type="button"
                          phx-click="cancel-upload"
                          phx-value-ref={entry.ref}
                          phx-target={@myself}
                          class="absolute -top-2 -right-2 inline-flex h-6 w-6 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-400 hover:text-gray-500"
                        >
                          <Heroicons.icon name="x-mark" class="h-4 w-4" />
                        </button>
                      </div>
                      <%= for err <- upload_errors(@uploads.product_image, entry) do %>
                        <div class="text-red-500 text-sm">{error_message(err)}</div>
                      <% end %>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
          
    <!-- SKUs Section -->
          <div class="border-t border-gray-200 pt-6">
            <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">
              Product Variants (SKUs)
            </h3>

            <%= if @skus != [] do %>
              <div class="mb-4 overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Variant
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Barcode
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Price
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Stock
                      </th>
                      <th scope="col" class="relative px-3 py-2">
                        <span class="sr-only">Actions</span>
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for sku <- @skus do %>
                      <tr>
                        <td class="px-3 py-2 whitespace-nowrap text-sm font-medium text-gray-900">
                          {sku.name}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                          {sku.barcode}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                          KSh {sku.price}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                          {sku.stock_quantity}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-right text-sm font-medium">
                          <button
                            type="button"
                            phx-click="remove_sku"
                            phx-value-id={sku.id}
                            phx-target={@myself}
                            class="text-red-600 hover:text-red-900"
                          >
                            Remove
                          </button>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>

            <%= if @show_sku_form do %>
              <div class="mt-4 bg-gray-50 rounded-lg p-4">
                <.form
                  for={@sku_form}
                  phx-target={@myself}
                  phx-change="validate_sku"
                  phx-submit="add_sku"
                  id="sku-form"
                >
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <.input
                        field={@sku_form[:name]}
                        type="text"
                        label="Variant Name"
                        placeholder="e.g. 500g, Red"
                        required
                      />
                    </div>
                    <div>
                      <.input
                        field={@sku_form[:barcode]}
                        type="text"
                        label="Barcode"
                        placeholder="Enter barcode"
                      />
                    </div>
                    <div>
                      <.input
                        field={@sku_form[:price]}
                        type="text"
                        label="Selling Price (KSh)"
                        placeholder="0.00"
                        required
                      />
                    </div>
                    <div>
                      <.input
                        field={@sku_form[:cost]}
                        type="text"
                        label="Cost Price (KSh)"
                        placeholder="0.00"
                        required
                      />
                    </div>
                    <div>
                      <.input
                        field={@sku_form[:stock_quantity]}
                        type="number"
                        label="Current Stock"
                        placeholder="0"
                        required
                      />
                    </div>
                    <div>
                      <.input
                        field={@sku_form[:buffer_level]}
                        type="number"
                        label="Reorder Level"
                        placeholder="10"
                      />
                    </div>
                    <div class="md:col-span-2">
                      <.input
                        field={@sku_form[:description]}
                        type="textarea"
                        label="Variant Description"
                        rows="2"
                      />
                    </div>
                  </div>

                  <div class="mt-4 flex justify-end space-x-3">
                    <button
                      type="button"
                      phx-click="hide_sku_form"
                      phx-target={@myself}
                      class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
                    >
                      Add Variant
                    </button>
                  </div>
                </.form>
              </div>
            <% else %>
              <button
                type="button"
                phx-click="show_sku_form"
                phx-target={@myself}
                class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <Heroicons.icon name="plus" class="h-4 w-4 mr-2" /> Add Product Variant
              </button>
            <% end %>
          </div>

          <div class="flex justify-end space-x-3 pt-5 border-t border-gray-200">
            <.link
              patch={@patch}
              class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Cancel
            </.link>
            <.button type="submit" phx-disable-with="Saving...">
              Save Product
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp category_options do
    # Placeholder - in a real implementation, you'd query the database
    [
      {"Select Category", ""},
      {"Groceries", "1"},
      {"Household", "2"},
      {"Electronics", "3"},
      {"Personal Care", "4"},
      {"Beverages", "5"}
    ]
  end

  defp error_message(:too_large), do: "File is too large (max 5MB)"
  defp error_message(:not_accepted), do: "Invalid file type (allowed: .jpg, .jpeg, .png)"
  defp error_message(:too_many_files), do: "You can only upload one image"
  defp error_message(_), do: "Invalid file"
end
