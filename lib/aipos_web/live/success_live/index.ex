defmodule AiposWeb.SuccessLive.Index do
  use AiposWeb, :live_view
  alias Aipos.Sales

  def mount(%{"trxref" => transaction_id}, _session, socket) do
    {:ok,
     socket
     |> assign(:transaction_id, transaction_id)
     |> assign(:sale, nil)
     |> assign(:sale_items, [])
     |> assign(:loading, true)}
  end

  def handle_params(%{"trxref" => transaction_id}, _uri, socket) do
    case get_and_update_sale(transaction_id) do
      {:ok, sale, sale_items} ->
        Aipos.Tiara.send_message(
          sale.phone_number,
          "Your payment was successful. Thank you for your order."
        )

        {:noreply,
         socket
         |> assign(:sale, sale)
         |> assign(:sale_items, sale_items)
         |> assign(:loading, false)
         |> IO.inspect(label: "Sale and Sale Items")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:error, "We couldn't find your order. Please contact support.")}
    end
  end

  defp get_and_update_sale(transaction_id) do
    # Get the sale by transaction_id
    case Sales.get_sale_by_transaction_id(transaction_id) do
      nil ->
        {:error, :not_found}

      sale ->
        # Update sale status to completed
        {:ok, updated_sale} =
          Sales.update_sale(sale, %{status: "completed", paid_at: DateTime.utc_now()})

        # Get sale items
        sale_items = Sales.list_sale_items_by_sale_id(sale.id)

        {:ok, updated_sale, sale_items}
    end
  end

  def handle_event("download_receipt", _, socket) do
    # Placeholder for future download functionality
    {:noreply,
     socket
     |> put_flash(:info, "Receipt download feature coming soon!")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-12">
      <%= if @loading do %>
        <div class="w-full flex flex-col items-center justify-center p-8">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mb-4"></div>
          <p class="text-gray-600 text-lg">Processing your order...</p>
        </div>
      <% else %>
        <%= if @sale do %>
          <div class="max-w-2xl mx-auto bg-white shadow-lg rounded-lg overflow-hidden">
            <!-- Success Header -->
            <div class="bg-green-50 p-6 border-b border-green-100">
              <div class="flex items-center">
                <div class="bg-green-100 rounded-full p-2 mr-4">
                  <Heroicons.icon name="check-circle" class="h-8 w-8 text-green-600" />
                </div>
                <div>
                  <h1 class="text-2xl font-bold text-gray-800">Payment Successful!</h1>
                  <p class="text-gray-600">
                    Thank you for your purchase. Your order has been confirmed.
                  </p>
                </div>
              </div>
            </div>
            
    <!-- Order Details -->
            <div class="p-6">
              <div class="mb-6">
                <h2 class="text-lg font-semibold text-gray-800 mb-2">Order Summary</h2>
                <div class="flex justify-between text-sm text-gray-600 mb-1">
                  <span>Transaction ID:</span>
                  <span class="font-medium">{@sale.transaction_id}</span>
                </div>
                <div class="flex justify-between text-sm text-gray-600 mb-1">
                  <span>Date:</span>
                  <span class="font-medium">
                    {Calendar.strftime(@sale.inserted_at, "%B %d, %Y at %I:%M %p")}
                  </span>
                </div>
                <div class="flex justify-between text-sm text-gray-600">
                  <span>Payment Method:</span>
                  <span class="font-medium">
                    <%= case @sale.payment_method do %>
                      <% "pay_now" -> %>
                        Online Payment
                      <% "pay_on_delivery" -> %>
                        Pay on Delivery
                      <% _ -> %>
                        {@sale.payment_method}
                    <% end %>
                  </span>
                </div>
              </div>
              
    <!-- Items -->
              <div class="mb-6">
                <h2 class="text-lg font-semibold text-gray-800 mb-2">Items Purchased</h2>
                <div class="border rounded-md overflow-hidden">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th
                          scope="col"
                          class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                        >
                          Item
                        </th>
                        <th
                          scope="col"
                          class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase"
                        >
                          Qty
                        </th>
                        <th
                          scope="col"
                          class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase"
                        >
                          Price
                        </th>
                        <th
                          scope="col"
                          class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase"
                        >
                          Total
                        </th>
                      </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                      <%= for item <- @sale_items do %>
                        <tr>
                          <td class="px-4 py-3 whitespace-nowrap text-sm font-medium text-gray-900">
                            {item.name}
                          </td>
                          <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 text-center">
                            {item.quantity}
                          </td>
                          <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 text-right">
                            KSh {Decimal.to_string(item.price)}
                          </td>
                          <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 text-right">
                            KSh {Decimal.to_string(item.subtotal)}
                          </td>
                        </tr>
                      <% end %>
                      <%!-- shipping of 250 always --%>

                      <tr class="bg-gray-50">
                        <td colspan="3" class="px-4 py-3 text-sm font-medium text-gray-900 text-right">
                          Shipping:
                        </td>
                        <td class="px-4 py-3 text-sm font-medium text-gray-900 text-right">
                          KSh 250
                        </td>
                      </tr>
                    </tbody>
                    <tfoot class="bg-gray-50">
                      <tr>
                        <td colspan="3" class="px-4 py-3 text-sm font-medium text-gray-900 text-right">
                          Total:
                        </td>
                        <td class="px-4 py-3 text-sm font-medium text-gray-900 text-right">
                          KSh {Decimal.to_string(@sale.total_amount)}
                        </td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              </div>
              
    <!-- Actions -->
              <div class="flex justify-between items-center mt-8">
                <a href="/" class="inline-flex items-center text-blue-600 hover:text-blue-800">
                  <Heroicons.icon name="arrow-left" class="h-4 w-4 mr-1" /> Return to Marketplace
                </a>
                <div class="space-x-3">
                  <button
                    phx-click="download_receipt"
                    class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    <Heroicons.icon name="document-arrow-down" class="h-4 w-4 mr-1" />
                    Download Receipt
                  </button>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <div class="max-w-md mx-auto bg-white shadow-lg rounded-lg overflow-hidden p-6 text-center">
            <div class="bg-yellow-50 rounded-full p-4 mx-auto w-16 h-16 flex items-center justify-center mb-4">
              <Heroicons.icon name="exclamation-triangle" class="h-8 w-8 text-yellow-600" />
            </div>
            <h2 class="text-xl font-semibold text-gray-800 mb-2">Order Not Found</h2>
            <p class="text-gray-600 mb-6">
              We couldn't find your order information. Please contact customer support for assistance.
            </p>
            <a
              href="/"
              class="inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Return to Marketplace
            </a>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
