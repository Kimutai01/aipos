defmodule AiposWeb.ProductSkuLive.Index do
  use AiposWeb, :live_view

  alias Aipos.Products
  alias Aipos.ProductSkus
  alias Aipos.ProductSkus.ProductSku

  @impl true
  def mount(%{"product_id" => product_id}, _session, socket) do
    product = Products.get_product!(product_id)
    product_skus = ProductSkus.list_product_skus(product_id)

    socket =
      socket
      |> assign(:active_page, "products")
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(:current_organization, get_organization(socket.assigns.current_user))
      |> assign(:product, product)
      |> assign(:product_skus, product_skus)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    product_id = socket.assigns.product.id
    product_skus = ProductSkus.list_product_skus(product_id)
    socket = assign(socket, :product_skus, product_skus)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit SKU")
    |> assign(:product_sku, ProductSkus.get_product_sku!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New SKU")
    |> assign(:product_sku, %ProductSku{product_id: socket.assigns.product.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.product.name} - SKUs")
    |> assign(:product_sku, nil)
  end

  defp apply_action(socket, nil, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.product.name} - SKUs")
    |> assign(:product_sku, nil)
  end

  @impl true
  def handle_info({AiposWeb.ProductSkuLive.FormComponent, {:saved, _product_sku}}, socket) do
    product_id = socket.assigns.product.id
    {:noreply, assign(socket, :product_skus, ProductSkus.list_product_skus(product_id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product_sku = ProductSkus.get_product_sku!(id)
    {:ok, _} = ProductSkus.delete_product_sku(product_sku)

    product_id = socket.assigns.product.id
    {:noreply, assign(socket, :product_skus, ProductSkus.list_product_skus(product_id))}
  end

  defp get_organization(user) do
    Aipos.Organizations.get_organization!(user.organization_id)
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

      <div class="flex-1 pl-64 overflow-y-auto">
        <header class="bg-white shadow sticky top-0 z-10">
          <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between">
              <div>
                <.link
                  navigate={~p"/products"}
                  class="inline-flex items-center text-gray-500 hover:text-gray-700 mb-2"
                >
                  <Heroicons.icon name="arrow-left" class="h-4 w-4 mr-1" /> Back to Products
                </.link>
                <h1 class="text-xl font-bold tracking-tight text-gray-900">
                  {@product.name} - SKUs
                </h1>
              </div>
              <div>
                <.link
                  patch={~p"/products/#{@product}/skus/new"}
                  class="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
                >
                  <Heroicons.icon name="plus" class="h-4 w-4 mr-1" /> Add SKU
                </.link>
              </div>
            </div>
          </div>
        </header>

        <main class="mx-auto max-w-7xl py-6 px-4 sm:px-6 lg:px-8">
          <div class="bg-white shadow rounded-lg">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Image
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Variant
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Barcode
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Price
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Cost
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Stock
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody id="product_skus" class="bg-white divide-y divide-gray-200">
                  <%= for sku <- @product_skus do %>
                    <tr id={"product-sku-#{sku.id}"} class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex-shrink-0 h-10 w-10">
                          <%= if sku.image do %>
                            <img
                              class="h-10 w-10 rounded-full object-cover"
                              src={sku.image}
                              alt={sku.name}
                            />
                          <% else %>
                            <div class="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                              <Heroicons.icon name="photo" class="h-6 w-6 text-gray-400" />
                            </div>
                          <% end %>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-gray-900">{sku.name}</div>
                        <%= if sku.description && sku.description != "" do %>
                          <div class="text-xs text-gray-500">{sku.description}</div>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-mono text-gray-900">{sku.barcode || "-"}</div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">KSh {format_price(sku.price)}</div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">KSh {format_price(sku.cost)}</div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">
                          {sku.stock_quantity}
                          <%= if sku.buffer_level do %>
                            <span class="text-xs ml-1">(min: {sku.buffer_level})</span>
                          <% end %>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <.link
                          patch={~p"/products/#{@product}/skus/#{sku}/edit"}
                          class="text-blue-600 hover:text-blue-900 mr-3"
                        >
                          Edit
                        </.link>
                        <.link
                          phx-click={JS.push("delete", value: %{id: sku.id})}
                          data-confirm="Are you sure you want to delete this SKU?"
                          class="text-red-600 hover:text-red-900"
                        >
                          Delete
                        </.link>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="product-sku-modal"
        show
        on_cancel={JS.patch(~p"/products/#{@product}/skus")}
      >
        <.live_component
          module={AiposWeb.ProductSkuLive.FormComponent}
          id={@product_sku.id || :new}
          title={@page_title}
          action={@live_action}
          product_sku={@product_sku}
          product={@product}
          current_user={@current_user}
          patch={~p"/products/#{@product}/skus"}
        />
      </.modal>
    </div>
    """
  end

  # Helper function to format price values
  defp format_price(nil), do: "0.00"

  # Handle Decimal type (most likely case in your schema)
  defp format_price(%Decimal{} = price) do
    price
    |> Decimal.to_string()
  end

  # Handle string values
  defp format_price(price) when is_binary(price) do
    case Float.parse(price) do
      {float_price, _} -> :erlang.float_to_binary(float_price, decimals: 2)
      :error -> "0.00"
    end
  end

  # Handle integer values
  defp format_price(price) when is_integer(price) do
    :erlang.float_to_binary(price / 100, decimals: 2)
  end

  # Handle float values
  defp format_price(price) when is_float(price) do
    :erlang.float_to_binary(price, decimals: 2)
  end

  # Default fallback
  defp format_price(_), do: "0.00"
end
