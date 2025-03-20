defmodule AiposWeb.ProductLive.Index do
  use AiposWeb, :live_view

  alias Aipos.Products
  alias Aipos.Products.Product

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_page, "products")
      |> assign(:current_organization, get_organization(socket.assigns.current_user))
      |> stream(:products, Products.list_products())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, Products.get_product!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Product")
    |> assign(:product, %Product{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Products Inventory")
    |> assign(:product, nil)
  end

  defp apply_action(socket, nil, _params) do
    socket
    |> assign(:page_title, "Products Inventory")
    |> assign(:product, nil)
  end

  @impl true
  def handle_info({AiposWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, stream_insert(socket, :products, product)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _} = Products.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end

  # Helper function to get organization - replace with your actual implementation
  defp get_organization(user) do
    %{
      id: user.organization_id,
      name: "Sample Organization",
      logo: "/uploads/73286_Screenshot 2025-03-20 at 02.16.35.png"
    }
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

      <div class="flex-1 pl-64 overflow-hidden">
        <header class="bg-white shadow">
          <div class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between">
              <h1 class="text-xl font-bold tracking-tight text-gray-900">Products Inventory</h1>
              <div>
                <.link
                  patch={~p"/products/new"}
                  class="inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
                >
                  <Heroicons.icon name="plus" class="h-4 w-4 mr-1" /> Add Product
                </.link>
              </div>
            </div>
          </div>
        </header>

        <main class="mx-auto max-w-7xl py-6 px-4 sm:px-6 lg:px-8">
          <div class="bg-white shadow rounded-lg overflow-hidden">
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
                      Name
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Description
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      SKUs
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Category
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody id="products" class="bg-white divide-y divide-gray-200">
                  <%= for {id, product} <- @streams.products do %>
                    <tr id={id} class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex-shrink-0 h-10 w-10">
                          <%= if product.image do %>
                            <img
                              class="h-10 w-10 rounded-full object-cover"
                              src={product.image}
                              alt={product.name}
                            />
                          <% else %>
                            <div class="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                              <Heroicons.icon name="photo" class="h-6 w-6 text-gray-400" />
                            </div>
                          <% end %>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-gray-900">{product.name}</div>
                      </td>
                      <td class="px-6 py-4">
                        <div class="text-sm text-gray-500 line-clamp-2">{product.description}</div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-500">
                          {length(product.skus || [])}
                          <.link
                            navigate={~p"/products/#{product}/skus"}
                            class="ml-2 text-blue-600 hover:text-blue-800"
                          >
                            View
                          </.link>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <%= if product.category do %>
                          <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                            {product.category}
                          </span>
                        <% else %>
                          <span class="text-sm text-gray-500">—</span>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <.link
                          patch={~p"/products/#{product}/edit"}
                          class="text-blue-600 hover:text-blue-900 mr-3"
                        >
                          Edit
                        </.link>
                        <.link
                          phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
                          data-confirm="Are you sure you want to delete this product and all its SKUs?"
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
        id="product-modal"
        show
        on_cancel={JS.patch(~p"/products")}
      >
        <.live_component
          module={AiposWeb.ProductLive.FormComponent}
          id={@product.id || :new}
          title={@page_title}
          action={@live_action}
          product={@product}
          current_user={@current_user}
          patch={~p"/products"}
        />
      </.modal>
    </div>
    """
  end
end
