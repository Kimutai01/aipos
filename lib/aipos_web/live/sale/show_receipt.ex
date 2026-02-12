defmodule AiposWeb.Sale.ShowReceipt do
  use AiposWeb, :live_view
  alias Aipos.Sales
  alias Aipos.ReceiptSettings

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_organization = get_organization(socket.assigns.current_user)
    receipt_settings = ReceiptSettings.get_or_create_receipt_settings(current_organization.id)
    
    sale = 
      Sales.get_sale!(id)
      |> Aipos.Repo.preload([:sale_items, :register, :cashier])
    
    # Load customer separately if exists
    customer = 
      if sale.customer_id do
        try do
          Aipos.Customers.get_customer!(sale.customer_id)
        rescue
          _ -> nil
        end
      else
        nil
      end

    # Verify the sale belongs to the current organization
    if sale.organization_id != current_organization.id do
      {:ok,
       socket
       |> put_flash(:error, "Sale not found or access denied")
       |> redirect(to: ~p"/sales")}
    else
      socket =
        socket
        |> assign(:active_page, "sales")
        |> assign(:current_organization, current_organization)
        |> assign(:receipt_settings, receipt_settings)
        |> assign(:sale, sale)
        |> assign(:customer, customer)

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("print_receipt", _, socket) do
    {:noreply, push_event(socket, "print_receipt", %{})}
  end

  defp get_organization(user) do
    Aipos.Organizations.get_organization!(user.organization_id)
  end

  defp format_money(amount) when is_number(amount) do
    amount
    |> Decimal.from_float()
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
  end

  defp format_money(%Decimal{} = amount) do
    amount
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
  end

  defp format_money(_), do: "0.00"

  # Calculate VAT breakdown for Kenya (16% VAT inclusive)
  defp calculate_vat_breakdown(total_amount) do
    vat_rate = Decimal.new("0.16")
    divisor = Decimal.add(Decimal.new("1"), vat_rate) # 1.16
    
    subtotal = Decimal.div(total_amount, divisor)
    vat_amount = Decimal.mult(subtotal, vat_rate)
    
    %{
      subtotal: subtotal,
      vat_amount: vat_amount,
      vat_rate: "16%",
      total: total_amount
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-gray-100" id="sale-receipt-container" phx-hook="BarcodeScanner">
      <.live_component
        module={AiposWeb.Sidebar}
        id="sidebar"
        current_user={@current_user}
        current_organization={@current_organization}
        active_page={@active_page}
      />

      <div class="flex-1 pl-64 flex flex-col">
        <!-- Sticky Header with Navigation -->
        <div class="bg-white shadow-sm border-b border-gray-200 px-6 py-4 sticky top-0 z-10">
          <div class="max-w-4xl mx-auto flex items-center justify-between">
            <.link 
              navigate={~p"/sales"} 
              class="inline-flex items-center px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium rounded-lg transition-colors"
            >
              <Heroicons.icon name="arrow-left" class="h-5 w-5 mr-2" />
              Back to Sales
            </.link>
            
            <div class="flex items-center gap-3">
              <span class="text-sm text-gray-600 font-medium">Receipt #{@sale.id}</span>
              <button
                type="button"
                phx-click="print_receipt"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-lg shadow-sm text-white bg-blue-600 hover:bg-blue-700 transition-colors"
              >
                <Heroicons.icon name="printer" class="h-5 w-5 mr-2" />
                Print Receipt
              </button>
            </div>
          </div>
        </div>

        <!-- Scrollable Content Area -->
        <div class="flex-1 overflow-auto bg-gray-50 py-6 px-4">
          <div class="mx-auto max-w-2xl">

          <div class="bg-white shadow-xl rounded-lg overflow-hidden" style="max-width: 600px; margin: 0 auto;">
            <!-- Receipt content -->
            <div id="receipt-content" class="p-8" style="font-family: 'Courier New', monospace;">
              <%= if @receipt_settings.header_text do %>
                <div class="text-center text-sm text-gray-600 mb-4">
                  <%= for line <- String.split(@receipt_settings.header_text, "\n") do %>
                    <p>{line}</p>
                  <% end %>
                </div>
              <% end %>

              <div class="text-center mb-4">
                <%= if @receipt_settings.show_logo && @current_organization.logo do %>
                  <div class="flex justify-center mb-2">
                    <img
                      src={@current_organization.logo}
                      alt="Logo"
                      class="h-12 w-12 object-contain"
                    />
                  </div>
                <% end %>

                <%= if @receipt_settings.show_organization_name do %>
                  <h3 class="text-xl font-bold uppercase">{@current_organization.name}</h3>
                <% end %>

                <%= if @receipt_settings.show_location && @current_organization.location do %>
                  <p class="text-sm text-gray-700 font-semibold">{@current_organization.location}</p>
                <% end %>

                <%= if @receipt_settings.show_address && @current_organization.address do %>
                  <p class="text-sm text-gray-600">{@current_organization.address}</p>
                <% end %>

                <%= if @receipt_settings.show_phone && @current_organization.phone do %>
                  <p class="text-sm text-gray-600">Tel: {@current_organization.phone}</p>
                <% end %>

                <%= if @receipt_settings.show_email && @current_organization.email do %>
                  <p class="text-sm text-gray-600">Email: {@current_organization.email}</p>
                <% end %>

                <%= if @receipt_settings.show_kra_pin && @current_organization.kra_pin do %>
                  <p class="text-sm text-gray-600 font-semibold">VAT No: {@current_organization.kra_pin}</p>
                  <p class="text-sm text-gray-600">PIN: {@current_organization.kra_pin}</p>
                <% end %>
              </div>

              <div class="border-t border-b border-gray-300 py-2 mb-3">
                <div class="text-xs space-y-1">
                  <div class="flex justify-between">
                    <span class="text-gray-600">Receipt #:</span>
                    <span class="font-semibold">{@sale.id}</span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-gray-600">Date:</span>
                    <span class="font-semibold">
                      {Calendar.strftime(@sale.inserted_at, "%d/%m/%Y %H:%M")}
                    </span>
                  </div>

                  <%= if @sale.transaction_id do %>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Transaction ID:</span>
                      <span class="font-semibold text-xs">{@sale.transaction_id}</span>
                    </div>
                  <% end %>

                  <%= if @receipt_settings.show_cashier && @sale.cashier do %>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Cashier:</span>
                      <span class="font-semibold">{@sale.cashier.email}</span>
                    </div>
                  <% end %>

                  <%= if @receipt_settings.show_register && @sale.register do %>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Register:</span>
                      <span class="font-semibold">{@sale.register.name}</span>
                    </div>
                  <% end %>

                  <%= if @receipt_settings.show_customer && @customer do %>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Customer:</span>
                      <span class="font-semibold">{@customer.name || @customer.phone}</span>
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="mb-3">
                <div class="text-xs font-semibold text-gray-700 mb-1 pb-1 border-b border-gray-400">
                  ITEMS
                </div>
                <%= for item <- @sale.sale_items do %>
                  <div class="text-sm mb-2 py-1">
                    <div class="font-medium text-gray-900">{item.name}</div>
                    <div class="flex justify-between text-xs text-gray-600 mt-0.5">
                      <span>{item.quantity} x KSh {format_money(item.price)}</span>
                      <span class="font-semibold text-gray-900">KSh {format_money(item.subtotal)}</span>
                    </div>
                  </div>
                <% end %>
              </div>

              <div class="border-t-2 border-gray-400 pt-2 space-y-1">
                <%= if @receipt_settings.show_vat_breakdown do %>
                  <% vat_breakdown = calculate_vat_breakdown(@sale.total_amount) %>
                  
                  <div class="flex justify-between text-xs">
                    <span class="text-gray-600">Subtotal (Excl. VAT):</span>
                    <span>KSh {format_money(vat_breakdown.subtotal)}</span>
                  </div>
                  
                  <div class="flex justify-between text-xs">
                    <span class="text-gray-600">VAT ({vat_breakdown.vat_rate}):</span>
                    <span>KSh {format_money(vat_breakdown.vat_amount)}</span>
                  </div>
                  
                  <div class="flex justify-between text-base font-bold border-t border-gray-300 pt-1 mt-1">
                    <span>TOTAL (Incl. VAT):</span>
                    <span>KSh {format_money(@sale.total_amount)}</span>
                  </div>
                <% else %>
                  <div class="flex justify-between text-base font-bold">
                    <span>TOTAL:</span>
                    <span>KSh {format_money(@sale.total_amount)}</span>
                  </div>
                <% end %>
                
                <div class="flex justify-between text-xs mt-2 pt-1 border-t border-gray-200">
                  <span class="text-gray-600">Payment Method:</span>
                  <span class="font-medium uppercase">{@sale.payment_method}</span>
                </div>

                <%= if @sale.payment_method == "cash" do %>
                  <div class="flex justify-between text-xs">
                    <span class="text-gray-600">Amount Tendered:</span>
                    <span>KSh {format_money(@sale.amount_tendered)}</span>
                  </div>
                  <%= if Decimal.compare(@sale.change_due, Decimal.new(0)) == :gt do %>
                    <div class="flex justify-between text-xs">
                      <span class="text-gray-600">Change:</span>
                      <span class="text-green-600 font-semibold">
                        KSh {format_money(@sale.change_due)}
                      </span>
                    </div>
                  <% end %>
                <% end %>

                <div class="flex justify-between text-xs mt-1 pt-1 border-t border-gray-200">
                  <span class="text-gray-600">Status:</span>
                  <span class={"font-medium uppercase #{if @sale.status == "completed", do: "text-green-600", else: "text-yellow-600"}"}>
                    {@sale.status}
                  </span>
                </div>
              </div>

              <div class="text-center mt-4 pt-3 border-t border-gray-300 text-xs text-gray-500">
                <%= if @receipt_settings.show_vat_breakdown do %>
                  <p class="font-semibold uppercase">PRICES INCLUSIVE OF 16% VAT</p>
                <% end %>

                <%= if @receipt_settings.footer_text do %>
                  <div class="mt-2">
                    <%= for line <- String.split(@receipt_settings.footer_text, "\n") do %>
                      <p class="mt-1">{line}</p>
                    <% end %>
                  </div>
                <% else %>
                  <p class="mt-2">Thank you for your business!</p>
                  <p class="mt-1">Please come again</p>
                <% end %>
              </div>
            </div>
          </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
