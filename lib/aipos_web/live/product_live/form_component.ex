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
     |> assign(:skus, [])
     |> assign(:show_sku_form, false)
     |> allow_upload(:product_image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 5_000_000,
       progress: &handle_progress/3
     )
     |> allow_upload(:sku_image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 5_000_000,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    IO.inspect(assigns, label: "Updating Product Form")
    # Make sure we have an initialized product
    product =
      case product do
        # New product
        %{id: nil} ->
          %Products.Product{product_skus: []}

        %{product_skus: %Ecto.Association.NotLoaded{}} ->
          # Existing product but skus not loaded
          Products.get_product!(product.id)

        _ ->
          # Product with skus already loaded
          product
      end

    changeset = Products.change_product(product)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:product, product)
     |> assign(:current_sku, %ProductSku{
       temp_id: get_temp_id(),
       stock_quantity: 0,
       buffer_level: 10,
       organization_id: assigns.current_user.organization_id,
       user_id: assigns.current_user.id
     })
     |> assign(:changeset, changeset)
     |> assign(:skus, product.product_skus || [])
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Products.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate_sku", %{"product_sku" => sku_params}, socket) do
    {:noreply,
     socket
     |> assign(:current_sku, Map.merge(socket.assigns.current_sku, atomize_keys(sku_params)))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :product_image, ref)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :product_image, fn %{path: path}, entry ->
        uploads_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(uploads_dir)

        filename = "#{:rand.uniform(100_000)}_#{Path.basename(entry.client_name)}"
        dest = Path.join(uploads_dir, filename)

        File.cp!(path, dest)

        {:ok, AiposWeb.Endpoint.static_path("/uploads/#{filename}")}
      end)

    # Update params with logo path
    product_params =
      case uploaded_files do
        [image_path | _] -> Map.put(product_params, "image", image_path)
        _ -> product_params
      end

    # Set organization_id if needed
    product_params =
      Map.put(product_params, "organization_id", socket.assigns.current_user.organization_id)

    IO.inspect(product_params, label: "Product Params")

    save_product(socket, socket.assigns.action, product_params)
  end

  # Shows the SKU form (modal)
  def handle_event("show_sku_form", _, socket) do
    {:noreply,
     socket
     |> assign(:show_sku_form, true)
     |> assign(:current_sku, %ProductSku{
       temp_id: get_temp_id(),
       stock_quantity: 0,
       buffer_level: 10
     })}
  end

  def handle_event("hide_sku_form", _, socket) do
    {:noreply, assign(socket, :show_sku_form, false)}
  end

  def handle_event("add_sku", _params, socket) do
    current_sku = socket.assigns.current_sku

    if current_sku.name && current_sku.name != "" do
      # Handle SKU image upload
      uploaded_files =
        consume_uploaded_entries(socket, :sku_image, fn %{path: path}, entry ->
          uploads_dir = Path.join(["priv", "static", "uploads"])
          File.mkdir_p!(uploads_dir)

          filename = "sku_#{:rand.uniform(100_000)}_#{Path.basename(entry.client_name)}"
          dest = Path.join(uploads_dir, filename)

          File.cp!(path, dest)

          {:ok, AiposWeb.Endpoint.static_path("/uploads/#{filename}")}
        end)

      # Update current_sku with image path if available
      current_sku =
        case uploaded_files do
          [image_path | _] -> Map.put(current_sku, :image, image_path)
          _ -> current_sku
        end

      # Ensure the organization_id is set from the current user
      current_sku =
        Map.put(current_sku, :organization_id, socket.assigns.current_user.organization_id)

      skus = socket.assigns.skus ++ [current_sku]

      {:noreply,
       socket
       |> assign(:skus, skus)
       |> assign(:show_sku_form, false)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_sku", %{"remove" => remove_id}, socket) do
    skus =
      Enum.reject(socket.assigns.skus, fn sku ->
        sku.temp_id == remove_id
      end)

    {:noreply, assign(socket, :skus, skus)}
  end

  def handle_event("mark_delete_sku", %{"id" => id}, socket) do
    id = String.to_integer(id)

    skus =
      Enum.map(socket.assigns.skus, fn sku ->
        if sku.id == id do
          Map.put(sku, :delete, true)
        else
          sku
        end
      end)

    {:noreply, assign(socket, :skus, skus)}
  end

  def handle_event("unmark_delete_sku", %{"id" => id}, socket) do
    id = String.to_integer(id)

    skus =
      Enum.map(socket.assigns.skus, fn sku ->
        if sku.id == id do
          Map.put(sku, :delete, false)
        else
          sku
        end
      end)

    {:noreply, assign(socket, :skus, skus)}
  end

  defp atomize_keys(map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end

  defp handle_progress(:product_image, entry, socket) do
    if entry.done? do
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp handle_progress(:sku_image, entry, socket) do
    if entry.done? do
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp save_product(socket, :edit, product_params) do
    case Products.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        save_product_skus(product.id, socket.assigns.skus)

        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:form, to_form(changeset))}
    end
  end

  defp save_product(socket, :new, product_params) do
    case Products.create_product(product_params) do
      {:ok, product} ->
        save_product_skus(product.id, socket.assigns.skus)

        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:form, to_form(changeset))}
    end
  end

  defp save_product_skus(product_id, skus) do
    Enum.each(skus, fn sku ->
      cond do
        sku.id && sku.delete ->
          ProductSkus.get_product_sku!(product_id, sku.id) |> ProductSkus.delete_product_sku()

        sku.id ->
          sku_params = %{
            name: sku.name,
            description: sku.description,
            barcode: sku.barcode,
            price: sku.price,
            cost: sku.cost,
            # Convert these to integers explicitly
            stock_quantity: ensure_integer(sku.stock_quantity),
            buffer_level: ensure_integer(sku.buffer_level),
            rfid_tag: sku.rfid_tag,
            image: sku.image,
            organization_id: ensure_integer(sku.organization_id)
          }

          IO.inspect(sku_params, label: "Updating SKU Params")

          ProductSkus.get_product_sku!(product_id, sku.id)
          |> ProductSkus.update_product_sku(sku_params)

        # If it doesn't have an ID, create it
        true ->
          sku_params = %{
            name: sku.name,
            description: sku.description || "",
            barcode: sku.barcode || "",
            price: Decimal.new(sku.price),
            cost: Decimal.new(sku.cost),
            # Convert these to integers explicitly
            stock_quantity: ensure_integer(sku.stock_quantity) || 0,
            buffer_level: ensure_integer(sku.buffer_level) || 10,
            rfid_tag: sku.rfid_tag || "",
            image: sku.image || "",
            product_id: product_id,
            organization_id: ensure_integer(sku.organization_id)
          }

          IO.inspect(sku_params, label: "Creating SKU Params")

          ProductSkus.create_product_sku(sku_params) |> IO.inspect(label: "Created SKU")
      end
    end)
  end

  # Add this helper function to ensure values are converted to integers
  defp ensure_integer(nil), do: nil
  defp ensure_integer(value) when is_integer(value), do: value

  defp ensure_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp get_temp_id, do: :crypto.strong_rand_bytes(5) |> Base.url_encode64() |> binary_part(0, 5)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg overflow-hidden max-w-2xl w-full mx-auto">
      <div class="bg-gradient-to-r from-blue-600 to-indigo-800 p-6">
        <h2 class="text-xl font-bold text-white">{@title}</h2>
        <p class="text-blue-100 mt-1 text-sm">
          Enter product details below. You can add variants (SKUs) for different sizes/types.
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
                placeholder="Enter product name (e.g., Maize Flour)"
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

            <div class="col-span-2 space-y-4">
              <label class="block text-sm font-medium text-gray-700">
                Product Image (Optional)
              </label>

              <.live_file_input
                upload={@uploads.product_image}
                class="block w-full text-sm text-gray-500
                  file:mr-4 file:py-2 file:px-4
                  file:rounded-md file:border-0
                  file:text-sm file:font-semibold
                  file:bg-blue-50 file:text-blue-700
                  hover:file:bg-blue-100"
              />

              <%= if @uploads.product_image.entries != [] do %>
                <%= for entry <- @uploads.product_image.entries do %>
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
                      <div class="bg-blue-600 h-2.5 rounded-full" style={"width: #{entry.progress}%"}>
                      </div>
                    </div>
                  <% end %>
                <% end %>
              <% end %>

              <%= for err <- @uploads.product_image.errors do %>
                <div class="text-sm text-red-500 mt-1">
                  <p>{error_to_string(err)}</p>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- SKUs Section -->
          <div class="border-t border-gray-200 pt-6">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-medium leading-6 text-gray-900">
                Product Variants (SKUs)
              </h3>

              <div class="text-sm text-gray-500">
                Add different sizes, packages, or variants of this product
              </div>
            </div>
            
    <!-- SKU Table -->
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
                        Cost
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
                          <div class="flex items-center">
                            <%= if sku.image do %>
                              <img src={sku.image} class="h-8 w-8 rounded-full object-cover mr-2" />
                            <% end %>
                            <div>
                              {sku.name}
                              <%= if sku.description && sku.description != "" do %>
                                <div class="text-xs text-gray-500">{sku.description}</div>
                              <% end %>
                            </div>
                          </div>
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                          {sku.barcode}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                          KSh {sku.price}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                          KSh {sku.cost}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                          {sku.stock_quantity}
                          <span class="text-xs">(min: {sku.buffer_level})</span>
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-right text-sm font-medium">
                          <%= if Map.has_key?(sku, :id) && sku.id do %>
                            <!-- Existing SKU - delete checkbox -->
                            <input
                              type="checkbox"
                              name={"sku_delete_#{sku.id}"}
                              value="true"
                              checked={Map.get(sku, :delete, false)}
                              phx-click={
                                if Map.get(sku, :delete, false),
                                  do: "unmark_delete_sku",
                                  else: "mark_delete_sku"
                              }
                              phx-value-id={sku.id}
                              phx-target={@myself}
                              class="mr-2"
                            />
                            <label class="text-red-600">Delete</label>
                          <% else %>
                            <!-- New SKU - remove button -->
                            <input
                              type="hidden"
                              name={"sku_temp_id_#{sku.temp_id}"}
                              value={sku.temp_id}
                            />
                            <button
                              type="button"
                              phx-click="remove_sku"
                              phx-value-remove={sku.temp_id}
                              phx-target={@myself}
                              class="text-red-600 hover:text-red-900"
                            >
                              Remove
                            </button>
                          <% end %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% else %>
              <div class="bg-gray-50 rounded p-4 mb-4 text-center text-sm text-gray-500">
                No variants added yet. Add your first variant below.
              </div>
            <% end %>
            
    <!-- Button to add SKU -->
            <div class="mt-4">
              <button
                type="button"
                phx-click="show_sku_form"
                phx-target={@myself}
                class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <Heroicons.icon name="plus" class="h-4 w-4 mr-2" /> Add Product Variant
              </button>
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
              Save Product
            </.button>
          </div>
        </.form>
      </div>
      
    <!-- SKU Form Modal -->
      <!-- SKU Form Modal with Correct Input Types -->
      <%= if @show_sku_form do %>
        <div class="fixed inset-0 flex items-center justify-center z-50">
          <div class="absolute inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>

          <div class="relative bg-white rounded-lg shadow-xl w-full max-w-md sm:max-w-lg mx-4 overflow-hidden">
            <div class="bg-blue-600 p-4">
              <h3 class="text-lg font-medium text-white">Add Product Variant</h3>
            </div>

            <div class="p-6">
              <form phx-submit="add_sku" phx-change="validate_sku" phx-target={@myself}>
                <div class="space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Variant Name</label>
                    <input
                      name="product_sku[name]"
                      value={@current_sku.name}
                      type="text"
                      class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      placeholder="e.g. 1KG, 2KG, 5KG"
                      required
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700">Barcode</label>
                    <input
                      name="product_sku[barcode]"
                      value={@current_sku.barcode}
                      type="text"
                      class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      placeholder="Enter barcode (optional)"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700">RFID Tag</label>
                    <input
                      name="product_sku[rfid_tag]"
                      value={@current_sku.rfid_tag}
                      type="text"
                      class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      placeholder="Enter RFID tag (optional)"
                    />
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700">
                        Selling Price (KSh)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        name="product_sku[price]"
                        value={@current_sku.price}
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                        required
                      />
                    </div>

                    <div>
                      <label class="block text-sm font-medium text-gray-700">Cost Price (KSh)</label>
                      <input
                        type="number"
                        step="0.01"
                        name="product_sku[cost]"
                        value={@current_sku.cost}
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                        required
                      />
                    </div>
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Current Stock</label>
                      <input
                        type="number"
                        step="1"
                        min="0"
                        name="product_sku[stock_quantity]"
                        value={@current_sku.stock_quantity}
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      />
                    </div>

                    <div>
                      <label class="block text-sm font-medium text-gray-700">Reorder Level</label>
                      <input
                        type="number"
                        step="1"
                        min="0"
                        name="product_sku[buffer_level]"
                        value={@current_sku.buffer_level}
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      />
                    </div>
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700">Description</label>
                    <textarea
                      name="product_sku[description]"
                      class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                      placeholder="Optional description for this variant"
                      rows="2"
                    ><%= @current_sku.description %></textarea>
                  </div>
                  
    <!-- Add SKU Image Upload -->
                  <div>
                    <label class="block text-sm font-medium text-gray-700">
                      Variant Image (Optional)
                    </label>

                    <.live_file_input
                      upload={@uploads.sku_image}
                      class="mt-1 block w-full text-sm text-gray-500
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
                              <p class="text-xs text-gray-500">
                                {trunc(entry.client_size / 1_000)} KB
                              </p>
                            </div>
                          </div>
                          <button
                            type="button"
                            phx-click="cancel-sku-upload"
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
                  </div>
                  
    <!-- Hidden field for organization_id -->
                  <input
                    type="hidden"
                    name="product_sku[organization_id]"
                    value={@current_user.organization_id}
                  />

                  <div class="flex justify-end space-x-3 pt-5">
                    <button
                      type="button"
                      phx-click="hide_sku_form"
                      phx-target={@myself}
                      class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
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
                </div>
              </form>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp category_options do
    [
      {"Select Category", ""},
      {"Groceries", "1"},
      {"Household", "2"},
      {"Electronics", "3"},
      {"Personal Care", "4"},
      {"Beverages", "5"}
    ]
  end

  defp error_to_string({:too_large, _}), do: "File is too large (max 5MB)"
  defp error_to_string({:too_many_files, _}), do: "You can upload only one logo"
  defp error_to_string({:not_accepted, _}), do: "Invalid file type (allowed: .jpg, .jpeg, .png)"
  defp error_to_string(_), do: "Invalid file"
end
