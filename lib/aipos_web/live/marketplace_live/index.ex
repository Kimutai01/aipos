defmodule AiposWeb.MarketplaceLive.Index do
  use AiposWeb, :live_view

  alias Aipos.Organizations
  alias Aipos.Products
  alias Aipos.Repo
  import Ecto.Query

  @shipping_cost Decimal.new("250.00")

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_page, "marketplace")
      |> assign(:organizations, Organizations.list_organizations())
      |> assign(:selected_organization, nil)
      |> assign(:products, [])
      |> assign(:cart_items, [])
      |> assign(:total_amount, Decimal.new(0))
      |> assign(:shipping_cost, @shipping_cost)
      |> assign(:search_query, "")
      |> assign(:search_results, [])
      |> assign(:guest_customer, %{id: nil, name: "", email: "", phone: ""})
      |> assign(:show_cart, false)
      |> assign(:show_checkout_form, false)
      |> assign(:redirecting, false)
      |> assign(:payment_method, nil)
      # New attribute for scanner state
      |> assign(:barcode_scanner_enabled, false)
      # Track last scanned barcode
      |> assign(:last_scanned_barcode, nil)
      |> assign(:scan_status, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Marketplace")
  end

  defp apply_action(socket, nil, _params) do
    socket
    |> assign(:page_title, "Marketplace")
  end

  def handle_event("barcode_scanned", %{"barcode" => barcode}, socket) do
    # We can only add items if an organization is selected
    if is_nil(socket.assigns.selected_organization) do
      {:noreply,
       socket
       |> assign(:last_scanned_barcode, barcode)
       |> assign(:scan_status, "Please select a store first")
       |> put_flash(:error, "Please select a store before scanning products")}
    else
      # Search for product by barcode
      case find_product_by_barcode(barcode, socket.assigns.selected_organization.id)
           |> IO.inspect() do
        nil ->
          {:noreply,
           socket
           |> assign(:last_scanned_barcode, barcode)
           |> assign(:scan_status, "Product not found")
           |> put_flash(:error, "Product with barcode #{barcode} not found")}

        product_sku ->
          if product_sku.stock_quantity <= 0 do
            {:noreply,
             socket
             |> assign(:last_scanned_barcode, barcode)
             |> assign(:scan_status, "Out of stock")
             |> put_flash(:error, "Product is out of stock")}
          else
            # Add product to cart
            cart_items = add_to_cart(socket.assigns.cart_items, product_sku)
            total = calculate_total(cart_items)

            {:noreply,
             socket
             |> assign(:cart_items, cart_items)
             |> assign(:total_amount, total)
             |> assign(:last_scanned_barcode, barcode)
             |> assign(:scan_status, "Added to cart")
             |> assign(:show_cart, true)
             |> put_flash(:info, "Added #{product_sku.name} to cart")}
          end
      end
    end
  end

  defp find_product_by_barcode(barcode, organization_id) do
    IO.inspect(barcode, label: "Barcode")
    IO.inspect(organization_id, label: "Organization ID")
    # Look up the product SKU by barcode
    from(s in Aipos.ProductSkus.ProductSku,
      where: s.barcode == ^barcode and s.organization_id == ^organization_id,
      preload: [:product]
    )
    |> Aipos.Repo.one()
  end

  def handle_event("toggle_scanner_mode", _, socket) do
    {:noreply, assign(socket, :barcode_scanner_enabled, !socket.assigns.barcode_scanner_enabled)}
  end

  @impl true
  def handle_event("toggle_cart", _, socket) do
    {:noreply, assign(socket, :show_cart, !socket.assigns.show_cart)}
  end

  def handle_event("select_organization", %{"id" => id}, socket) do
    organization_id = String.to_integer(id)
    organization = Organizations.get_organization!(organization_id)

    products =
      Products.list_products()
      |> Enum.filter(fn p -> p.organization_id == organization_id end)
      |> Enum.map(fn product ->
        skus =
          Products.list_product_skus(product.id)
          # Preload product association
          |> Enum.map(&Repo.preload(&1, :product))

        Map.put(product, :skus, skus)
      end)

    {:noreply,
     socket
     |> assign(:selected_organization, organization)
     |> assign(:products, products)}
  end

  def handle_event("add_to_cart", %{"sku-id" => sku_id}, socket) do
    sku_id = String.to_integer(sku_id)

    product_sku =
      Aipos.ProductSkus.get_product_sku!(sku_id)
      |> Repo.preload(:product)

    if product_sku.stock_quantity <= 0 do
      {:noreply,
       socket
       |> put_flash(:error, "Product is out of stock")}
    else
      cart_items = add_to_cart(socket.assigns.cart_items, product_sku)
      total = calculate_total(cart_items)

      {:noreply,
       socket
       |> assign(:cart_items, cart_items)
       |> assign(:total_amount, total)
       |> assign(:show_cart, true)}
    end
  end

  def handle_event("remove_item", %{"index" => index}, socket) do
    index = String.to_integer(index)
    cart_items = List.delete_at(socket.assigns.cart_items, index)
    total = calculate_total(cart_items)

    {:noreply,
     socket
     |> assign(:cart_items, cart_items)
     |> assign(:total_amount, total)}
  end

  def handle_event("update_quantity", %{"index" => index, "quantity" => quantity}, socket) do
    index = String.to_integer(index)
    quantity = String.to_integer(quantity)

    cart_items =
      List.update_at(socket.assigns.cart_items, index, fn item ->
        subtotal = Decimal.mult(item.price, Decimal.new(quantity))
        %{item | quantity: quantity, subtotal: subtotal}
      end)

    total = calculate_total(cart_items)

    {:noreply,
     socket
     |> assign(:cart_items, cart_items)
     |> assign(:total_amount, total)}
  end

  def handle_event("search_products", %{"query" => query}, socket) do
    results =
      if String.length(query) >= 2 and not is_nil(socket.assigns.selected_organization) do
        search_products(query, socket.assigns.selected_organization.id)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, results)}
  end

  def handle_event("add_from_search", %{"id" => id}, socket) do
    product_sku =
      Aipos.ProductSkus.get_product_sku!(id)
      # Preload product association
      |> Repo.preload(:product)

    cart_items = add_to_cart(socket.assigns.cart_items, product_sku)
    total = calculate_total(cart_items)

    {:noreply,
     socket
     |> assign(:cart_items, cart_items)
     |> assign(:total_amount, total)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:show_cart, true)}
  end

  def handle_event("proceed_to_checkout", _, socket) do
    if Enum.empty?(socket.assigns.cart_items) do
      {:noreply, put_flash(socket, :error, "Cannot checkout with empty cart")}
    else
      {:noreply, assign(socket, :show_checkout_form, true)}
    end
  end

  def handle_event("update_customer", %{"customer" => customer_params}, socket) do
    {:noreply,
     socket
     |> assign(:guest_customer, %{
       id: nil,
       name: Map.get(customer_params, "name", ""),
       email: Map.get(customer_params, "email", ""),
       phone: Map.get(customer_params, "phone", "")
     })}
  end

  def handle_event("select_payment_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, :payment_method, method)}
  end

  def handle_event("checkout", _, socket) do
    if Enum.empty?(socket.assigns.cart_items) do
      {:noreply, put_flash(socket, :error, "Cannot checkout with empty cart")}
    else
      # Validate customer information
      customer = socket.assigns.guest_customer

      cond do
        String.trim(customer.name) == "" ->
          {:noreply, put_flash(socket, :error, "Please enter your name")}

        String.trim(customer.phone) == "" ->
          {:noreply, put_flash(socket, :error, "Please enter your phone number")}

        is_nil(socket.assigns.payment_method) ->
          {:noreply, put_flash(socket, :error, "Please select a payment method")}

        true ->
          now = Aipos.TicketIdEncypter.now()

          total_price = Decimal.add(socket.assigns.total_amount, socket.assigns.shipping_cost)

          case Aipos.Paystack.initialize(
                 customer.email,
                 total_price,
                 now
               ) do
            %{"authorization_url" => authorization_url} ->
              sale_params = %{
                organization_id: socket.assigns.selected_organization.id,
                items: socket.assigns.cart_items,
                subtotal: socket.assigns.total_amount,
                shipping: socket.assigns.shipping_cost,
                total_amount:
                  Decimal.add(socket.assigns.total_amount, socket.assigns.shipping_cost),
                customer: socket.assigns.guest_customer,
                status: "pending",
                payment_method: socket.assigns.payment_method,
                transaction_id: now
              }

              IO.inspect(sale_params, label: "Sale Params")

              case Aipos.Sales.create_sale(sale_params) do
                {:ok, sale} ->
                  # Create sale items
                  Enum.each(socket.assigns.cart_items, fn item ->
                    item_params = %{
                      sale_id: sale.id,
                      product_sku_id: item.sku_id,
                      name: item.name,
                      quantity: item.quantity,
                      price: item.price,
                      subtotal: item.subtotal,
                      organization_id: socket.assigns.selected_organization.id
                    }

                    {:ok, _sale_item} = Aipos.Sales.create_sale_item(item_params)

                    update_stock_quantity(item.sku_id, item.quantity)
                  end)
              end

              {:noreply,
               socket
               |> assign(:redirecting, true)
               |> assign(:cart_items, [])
               |> assign(:total_amount, Decimal.new(0))
               |> assign(:show_cart, false)
               |> assign(:show_checkout_form, false)
               |> assign(:payment_method, nil)
               |> assign(:guest_customer, %{id: nil, name: "", email: "", phone: ""})
               |> redirect(external: authorization_url)}

            %{"error" => error} ->
              {:noreply,
               socket
               |> assign(:cart_items, [])
               |> assign(:total_amount, Decimal.new(0))
               |> assign(:show_cart, false)
               |> assign(:show_checkout_form, false)
               |> assign(:payment_method, nil)
               |> assign(:guest_customer, %{id: nil, name: "", email: "", phone: ""})
               |> assign(
                 :paystack_error,
                 "Failed to initialize payment , #{error}, Kindly try again"
               )}

            _ ->
              {:noreply,
               socket
               |> assign(:cart_items, [])
               |> assign(:total_amount, Decimal.new(0))
               |> assign(:show_cart, false)
               |> assign(:show_checkout_form, false)
               |> assign(:payment_method, nil)
               |> assign(:guest_customer, %{id: nil, name: "", email: "", phone: ""})
               |> assign(:paystack_error, "Failed to initialize payment, Kindly try again")}
          end
      end
    end
  end

  def handle_event("reset_cart", _, socket) do
    {:noreply,
     socket
     |> assign(:cart_items, [])
     |> assign(:total_amount, Decimal.new(0))}
  end

  def handle_event("cancel_checkout", _, socket) do
    {:noreply, assign(socket, :show_checkout_form, false)}
  end

  defp update_stock_quantity(sku_id, quantity) do
    sku = Aipos.ProductSkus.get_product_sku!(sku_id)
    new_quantity = sku.stock_quantity - quantity

    new_quantity = if new_quantity < 0, do: 0, else: new_quantity

    Aipos.ProductSkus.update_product_sku(sku, %{stock_quantity: new_quantity})
  end

  defp add_to_cart(cart_items, product_sku) do
    # Check if item already exists in cart
    case Enum.find_index(cart_items, &(&1.id == product_sku.id)) do
      nil ->
        # Add new item to cart
        product_name =
          if is_map(product_sku.product) &&
               !match?(%Ecto.Association.NotLoaded{}, product_sku.product) do
            product_sku.product.name
          else
            # If product is not loaded, use the SKU name
            product_sku.name
          end

        cart_item = %{
          id: product_sku.id,
          sku_id: product_sku.id,
          name: product_sku.name,
          product_name: product_name,
          barcode: product_sku.barcode,
          price: product_sku.price,
          quantity: 1,
          subtotal: product_sku.price,
          image: product_sku.image
        }

        cart_items ++ [cart_item]

      index ->
        # Increment quantity of existing item
        List.update_at(cart_items, index, fn item ->
          new_quantity = item.quantity + 1
          subtotal = Decimal.mult(item.price, Decimal.new(new_quantity))
          %{item | quantity: new_quantity, subtotal: subtotal}
        end)
    end
  end

  defp calculate_total(cart_items) do
    Enum.reduce(cart_items, Decimal.new(0), fn item, acc ->
      Decimal.add(acc, item.subtotal)
    end)
  end

  defp search_products(query, organization_id) do
    # Search for products that match the query
    from(s in Aipos.ProductSkus.ProductSku,
      join: p in assoc(s, :product),
      where:
        (ilike(s.name, ^"%#{query}%") or ilike(p.name, ^"%#{query}%") or
           ilike(s.barcode, ^"%#{query}%")) and s.organization_id == ^organization_id,
      preload: [:product],
      limit: 10
    )
    |> Aipos.Repo.all()
  end

  defp format_money(amount) when is_number(amount) do
    :erlang.float_to_binary(amount, decimals: 2)
  end

  defp format_money(%Decimal{} = amount) do
    Decimal.to_string(amount, :normal)
  end

  defp format_money(_), do: "0.00"

  @impl true

  def render(assigns) do
    ~H"""
    <%= if @redirecting do %>
      <div class="fixed inset-0 bg-gray-700 bg-opacity-75 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
          <div class="flex items-center justify-center">
            <Heroicons.icon name="refresh" class="h-8 w-8 animate-spin text-blue-500" />
          </div>
          <p class="text-center text-gray-700 mt-4">Redirecting to payment...</p>
        </div>
      </div>
    <% else %>
      <div class="flex min-h-screen flex-col bg-gray-100">
        <!-- Simple header/navigation bar -->
        <header class="bg-white shadow z-10">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex h-16 justify-between items-center">
              <div class="flex items-center">
                <h1 class="text-2xl font-bold text-gray-900">Marketplace</h1>
              </div>

              <div class="flex items-center space-x-4">
                <!-- Toggle self-checkout mode button -->
                <button
                  type="button"
                  phx-click="toggle_scanner_mode"
                  class={"p-2 rounded-md #{if @barcode_scanner_enabled, do: "bg-blue-100 text-blue-700", else: "text-gray-600 hover:text-gray-900"} focus:outline-none flex items-center"}
                >
                  <Heroicons.icon name="qr-code" class="h-6 w-6 mr-1" />
                  <span class="hidden md:inline text-sm font-medium">
                    {if @barcode_scanner_enabled,
                      do: "Self-Checkout Active",
                      else: "Enable Self-Checkout"}
                  </span>
                </button>

    <!-- Cart button -->
                <button
                  type="button"
                  phx-click="toggle_cart"
                  class="relative p-2 text-gray-600 hover:text-gray-900 focus:outline-none flex items-center"
                >
                  <Heroicons.icon name="shopping-cart" class="h-6 w-6 mr-1" />
                  <span class="hidden md:inline text-sm font-medium">
                    {if @show_cart, do: "Hide Cart", else: "Show Cart"}
                  </span>
                  <%= if !Enum.empty?(@cart_items) do %>
                    <span class="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-blue-600 text-xs font-medium text-white">
                      {Enum.count(@cart_items)}
                    </span>
                  <% end %>
                </button>
              </div>
            </div>
          </div>
        </header>
        <%= if @last_scanned_barcode && @scan_status do %>
          <div class="bg-blue-50 p-3 flex items-center">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center space-x-3">
              <Heroicons.icon
                name={
                  if @scan_status == "Added to cart", do: "check-circle", else: "exclamation-circle"
                }
                class={"h-5 w-5 #{if @scan_status == "Added to cart", do: "text-green-500", else: "text-amber-500"}"}
              />
              <span>
                Barcode: <span class="font-medium">{@last_scanned_barcode}</span>
                - {if @scan_status, do: @scan_status, else: ""}
              </span>
            </div>
          </div>
        <% end %>
        <!-- Main content with cart sidebar -->
        <div class="flex flex-1 flex-col md:flex-row">
          <!-- Main content area -->
          <main class="flex-1 container mx-auto px-4 py-6 md:pr-0 md:pl-4">
            <!-- Store selection -->
            <div class="mb-8">
              <h2 class="text-xl font-semibold mb-4">Select a Store</h2>
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <%= for org <- @organizations do %>
                  <button
                    phx-click="select_organization"
                    phx-value-id={org.id}
                    class={"p-4 rounded-lg border-2 text-center hover:bg-gray-50 transition-colors #{if @selected_organization && @selected_organization.id == org.id, do: "border-blue-500 bg-blue-50", else: "border-gray-200"}"}
                  >
                    <div class="font-medium">{org.name}</div>
                    <div class="text-sm text-gray-500 mt-1">
                      {if org.description, do: org.description, else: "Shop online"}
                    </div>
                  </button>
                <% end %>
              </div>
            </div>

            <%= if @barcode_scanner_enabled && @selected_organization do %>
              <div class="mb-6 bg-blue-50 p-4 rounded-lg border border-blue-200">
                <div class="flex items-start">
                  <div class="flex-shrink-0 pt-0.5">
                    <Heroicons.icon name="qr-code" class="h-6 w-6 text-blue-600" />
                  </div>
                  <div class="ml-3">
                    <h3 class="text-lg font-medium text-blue-800">Self-Checkout Mode Active</h3>
                    <p class="mt-1 text-blue-700">
                      Use the scanner button at the bottom right to scan product barcodes using your phone's camera.
                    </p>
                  </div>
                </div>
              </div>
            <% end %>

            <%= if @selected_organization do %>
              <!-- Product search -->
              <div class="mb-6">
                <div class="relative max-w-md mx-auto">
                  <input
                    type="text"
                    placeholder="Search products..."
                    value={@search_query}
                    phx-keyup="search_products"
                    phx-key="keyup"
                    phx-debounce="300"
                    class="w-full px-4 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                  <div class="absolute inset-y-0 right-0 flex items-center pr-3">
                    <Heroicons.icon name="magnifying-glass" class="h-5 w-5 text-gray-400" />
                  </div>
                </div>

                <%= if !Enum.empty?(@search_results) do %>
                  <div class="mt-2 bg-white shadow-md rounded-md border border-gray-200 max-h-80 overflow-y-auto z-20 relative">
                    <%= for product_sku <- @search_results do %>
                      <div class="p-3 border-b border-gray-200 flex justify-between items-center hover:bg-gray-50">
                        <div class="flex items-center">
                          <%= if product_sku.image do %>
                            <div class="w-12 h-12 rounded-md mr-3 bg-gray-200 overflow-hidden">
                              <img
                                src={product_sku.image}
                                alt={product_sku.name}
                                class="w-full h-full object-cover"
                              />
                            </div>
                          <% else %>
                            <div class="w-12 h-12 rounded-md mr-3 bg-gray-200 flex items-center justify-center">
                              <Heroicons.icon name="photo" class="h-6 w-6 text-gray-400" />
                            </div>
                          <% end %>
                          <div>
                            <div class="font-medium">{product_sku.name}</div>
                            <div class="text-sm text-gray-500">
                              <%= if product_sku.product && !match?(%Ecto.Association.NotLoaded{}, product_sku.product) do %>
                                {product_sku.product.name}
                              <% end %>
                            </div>
                            <div class="text-sm font-semibold text-gray-900">
                              KSh {format_money(product_sku.price)}
                            </div>
                          </div>
                        </div>
                        <button
                          phx-click="add_from_search"
                          phx-value-id={product_sku.id}
                          class="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium hover:bg-blue-200"
                        >
                          Add to Cart
                        </button>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>

    <!-- Product listing -->
              <div>
                <h2 class="text-xl font-semibold mb-4">
                  Products from {@selected_organization.name}
                </h2>

                <%= if Enum.empty?(@products) do %>
                  <div class="bg-white p-8 rounded-lg shadow text-center text-gray-500">
                    <Heroicons.icon name="shopping-bag" class="h-12 w-12 mx-auto mb-4 text-gray-400" />
                    <p>No products available from this store</p>
                  </div>
                <% else %>
                  <%= for product <- @products do %>
                    <div class="mb-8">
                      <h3 class="text-lg font-medium mb-2 bg-gray-50 p-2 rounded">{product.name}</h3>
                      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                        <%= for sku <- product.skus do %>
                          <div class="bg-white rounded-lg shadow overflow-hidden border border-gray-200">
                            <div class="h-40 bg-gray-200">
                              <%= if sku.image do %>
                                <img
                                  src={sku.image}
                                  alt={sku.name}
                                  class="w-full h-full object-cover"
                                />
                              <% else %>
                                <div class="w-full h-full flex items-center justify-center">
                                  <Heroicons.icon name="photo" class="h-12 w-12 text-gray-400" />
                                </div>
                              <% end %>
                            </div>
                            <div class="p-4">
                              <h4 class="font-medium">{sku.name}</h4>
                              <div class="text-sm text-gray-500 mt-1">{sku.description}</div>
                              <div class="mt-2 flex justify-between items-center">
                                <div class="font-bold text-lg">KSh {format_money(sku.price)}</div>
                                <div class="text-sm text-gray-500">
                                  <%= if sku.stock_quantity > 0 do %>
                                    In stock: {sku.stock_quantity}
                                  <% else %>
                                    <span class="text-red-500">Out of stock</span>
                                  <% end %>
                                </div>
                              </div>
                              <button
                                phx-click="add_to_cart"
                                phx-value-sku-id={sku.id}
                                disabled={sku.stock_quantity <= 0}
                                class={"mt-3 w-full py-2 px-4 rounded-md text-sm font-medium text-white #{if sku.stock_quantity > 0, do: "bg-blue-600 hover:bg-blue-700", else: "bg-gray-300 cursor-not-allowed"}"}
                              >
                                Add to Cart
                              </button>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>
            <% else %>
              <div class="bg-white p-8 rounded-lg shadow text-center">
                <Heroicons.icon
                  name="building-storefront"
                  class="h-16 w-16 mx-auto mb-4 text-gray-400"
                />
                <h3 class="text-xl font-medium text-gray-900 mb-2">
                  Select a store to start shopping
                </h3>
                <p class="text-gray-500">Browse products and add them to your cart</p>
              </div>
            <% end %>
          </main>

    <!-- Cart sidebar - toggleable on both mobile and desktop, sticky positioning -->
          <aside class={"bg-white shadow-lg transition-all duration-300 overflow-hidden z-20
          #{if @show_cart, do: "w-full md:w-96", else: "w-0"}
          #{if @show_cart, do: "fixed inset-0 md:sticky md:top-0 md:right-0 md:h-screen md:inset-auto", else: ""}"}>
            <div class="p-4 h-full flex flex-col">
              <div class="flex justify-between items-center border-b pb-4">
                <h3 class="text-lg font-medium">Your Cart</h3>
                <button phx-click="toggle_cart" class="text-gray-500 hover:text-gray-700">
                  <Heroicons.icon name="x-mark" class="h-6 w-6" />
                </button>
              </div>

              <%= if Enum.empty?(@cart_items) do %>
                <div class="py-12 flex-1 flex flex-col items-center justify-center text-gray-500">
                  <Heroicons.icon name="shopping-cart" class="h-12 w-12 mb-4 text-gray-400" />
                  <p>Your cart is empty</p>
                </div>
              <% else %>
                <!-- Cart items -->
                <div class="flex-1 overflow-y-auto py-4">
                  <%= for {item, index} <- Enum.with_index(@cart_items) do %>
                    <div class="py-3 flex gap-3 border-b">
                      <!-- Item image -->
                      <div class="w-16 h-16 bg-gray-200 rounded overflow-hidden flex-shrink-0">
                        <%= if item.image do %>
                          <img src={item.image} alt={item.name} class="w-full h-full object-cover" />
                        <% else %>
                          <div class="w-full h-full flex items-center justify-center">
                            <Heroicons.icon name="photo" class="h-6 w-6 text-gray-400" />
                          </div>
                        <% end %>
                      </div>

    <!-- Item details -->
                      <div class="flex-1 min-w-0">
                        <div class="font-medium truncate">{item.name}</div>
                        <div class="text-sm text-gray-500 truncate">{item.product_name}</div>
                        <div class="mt-1 flex justify-between items-center">
                          <div class="text-sm font-semibold">
                            KSh {format_money(item.price)}
                          </div>
                          <div class="flex items-center">
                            <!-- Quantity controls using + and - buttons -->
                            <div class="flex items-center border rounded">
                              <button
                                phx-click="update_quantity"
                                phx-value-index={index}
                                phx-value-quantity={max(1, item.quantity - 1)}
                                class="px-2 py-1 text-gray-600 hover:bg-gray-100"
                                title="Decrease quantity"
                              >
                                <Heroicons.icon name="minus" class="h-4 w-4" />
                              </button>
                              <span class="px-2 py-1 text-sm font-medium min-w-[20px] text-center">
                                {item.quantity}
                              </span>
                              <button
                                phx-click="update_quantity"
                                phx-value-index={index}
                                phx-value-quantity={item.quantity + 1}
                                class="px-2 py-1 text-gray-600 hover:bg-gray-100"
                                title="Increase quantity"
                              >
                                <Heroicons.icon name="plus" class="h-4 w-4" />
                              </button>
                            </div>
                            <button
                              phx-click="remove_item"
                              phx-value-index={index}
                              class="ml-2 text-gray-400 hover:text-red-500"
                              title="Remove item"
                            >
                              <Heroicons.icon name="trash" class="h-4 w-4" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>

    <!-- Cart summary -->
                <div class="border-t pt-4 mt-auto">
                  <div class="flex justify-between text-sm">
                    <span>Subtotal</span>
                    <span>KSh {format_money(@total_amount)}</span>
                  </div>
                  <div class="flex justify-between text-sm text-gray-500 mt-2">
                    <span>Shipping</span>
                    <span>KSh {format_money(@shipping_cost)}</span>
                  </div>
                  <div class="flex justify-between font-bold mt-2 text-lg">
                    <span>Total</span>
                    <span>KSh {format_money(Decimal.add(@total_amount, @shipping_cost))}</span>
                  </div>

                  <div class="mt-4 flex gap-2">
                    <button
                      phx-click="reset_cart"
                      class="w-1/3 rounded border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                      disabled={Enum.empty?(@cart_items)}
                    >
                      Clear
                    </button>
                    <button
                      phx-click="proceed_to_checkout"
                      class="w-2/3 rounded bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700"
                      disabled={Enum.empty?(@cart_items)}
                    >
                      Checkout
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          </aside>
        </div>

    <!-- Checkout form overlay -->
        <%= if @show_checkout_form do %>
          <div class="fixed inset-0 bg-gray-700 bg-opacity-75 flex items-center justify-center z-50 p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
              <div class="p-6">
                <div class="flex justify-between items-center mb-4">
                  <h2 class="text-xl font-semibold">Complete Your Order</h2>
                  <button phx-click="cancel_checkout" class="text-gray-500 hover:text-gray-700">
                    <Heroicons.icon name="x-mark" class="h-6 w-6" />
                  </button>
                </div>

    <!-- Contact information -->
                <div class="mb-6">
                  <h3 class="text-lg font-medium mb-4">Contact Information</h3>
                  <form phx-change="update_customer">
                    <div class="mb-4">
                      <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                      <input
                        type="text"
                        name="customer[name]"
                        value={@guest_customer.name}
                        required
                        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                      />
                    </div>

                    <div class="mb-4">
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Email (optional)
                      </label>
                      <input
                        type="email"
                        name="customer[email]"
                        value={@guest_customer.email}
                        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                      />
                    </div>

                    <div class="mb-4">
                      <label class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                      <input
                        type="tel"
                        name="customer[phone]"
                        value={@guest_customer.phone}
                        required
                        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                      />
                    </div>
                  </form>
                </div>

    <!-- Order summary -->
                <div class="mb-6">
                  <h3 class="text-lg font-medium mb-2">Order Summary</h3>
                  <div class="bg-gray-50 rounded-md p-3">
                    <div class="max-h-40 overflow-y-auto mb-3">
                      <%= for {item, _index} <- Enum.with_index(@cart_items) do %>
                        <div class="py-2 flex items-center gap-2 border-b border-gray-200 last:border-0">
                          <div class="w-8 h-8 bg-gray-200 rounded overflow-hidden flex-shrink-0">
                            <%= if item.image do %>
                              <img
                                src={item.image}
                                alt={item.name}
                                class="w-full h-full object-cover"
                              />
                            <% else %>
                              <div class="w-full h-full flex items-center justify-center">
                                <Heroicons.icon name="photo" class="h-4 w-4 text-gray-400" />
                              </div>
                            <% end %>
                          </div>
                          <div class="flex-1 min-w-0">
                            <div class="text-sm font-medium truncate">{item.name}</div>
                          </div>
                          <div class="text-sm font-medium">
                            {item.quantity} × KSh {format_money(item.price)}
                          </div>
                        </div>
                      <% end %>
                    </div>

                    <div class="text-sm">
                      <div class="flex justify-between py-1">
                        <span>Subtotal</span>
                        <span>KSh {format_money(@total_amount)}</span>
                      </div>
                      <div class="flex justify-between py-1">
                        <span>Shipping</span>
                        <span>KSh {format_money(@shipping_cost)}</span>
                      </div>
                      <div class="flex justify-between pt-2 border-t mt-2 font-bold">
                        <span>Total</span>
                        <span>KSh {format_money(Decimal.add(@total_amount, @shipping_cost))}</span>
                      </div>
                    </div>
                  </div>
                </div>

    <!-- Payment method selection -->
                <div class="mb-6">
                  <h3 class="text-lg font-medium mb-2">Payment Method</h3>
                  <div class="space-y-3">
                    <div
                      class={"flex items-center p-3 border rounded-md cursor-pointer #{if @payment_method == "pay_now", do: "border-blue-500 bg-blue-50", else: "border-gray-300"}"}
                      phx-click="select_payment_method"
                      phx-value-method="pay_now"
                    >
                      <div class="flex-1">
                        <div class="font-medium">Pay Now</div>
                        <div class="text-sm text-gray-500">
                          Pay online with M-Pesa, card, or bank transfer
                        </div>
                      </div>
                      <div class="ml-3">
                        <%= if @payment_method == "pay_now" do %>
                          <Heroicons.icon name="check-circle" class="h-6 w-6 text-blue-500" />
                        <% end %>
                      </div>
                    </div>

                    <div
                      class={"flex items-center p-3 border rounded-md cursor-pointer #{if @payment_method == "pay_on_delivery", do: "border-blue-500 bg-blue-50", else: "border-gray-300"}"}
                      phx-click="select_payment_method"
                      phx-value-method="pay_on_delivery"
                    >
                      <div class="flex-1">
                        <div class="font-medium">Pay on Delivery</div>
                        <div class="text-sm text-gray-500">
                          Pay when your order is delivered to you
                        </div>
                      </div>
                      <div class="ml-3">
                        <%= if @payment_method == "pay_on_delivery" do %>
                          <Heroicons.icon name="check-circle" class="h-6 w-6 text-blue-500" />
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="mt-6 flex gap-3">
                  <button
                    phx-click="cancel_checkout"
                    class="w-1/3 px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50"
                  >
                    Cancel
                  </button>
                  <button
                    phx-click="checkout"
                    class="w-2/3 px-4 py-2 bg-blue-600 rounded-md shadow-sm text-sm font-medium text-white hover:bg-blue-700"
                  >
                    {if @payment_method == "pay_now", do: "Proceed to Payment", else: "Place Order"}
                  </button>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
      <div id="barcode-scanner-container" phx-hook="BarcodeScanner"></div>
    <% end %>
    """
  end
end
