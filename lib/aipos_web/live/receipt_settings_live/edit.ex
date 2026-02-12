defmodule AiposWeb.ReceiptSettingsLive.Edit do
  use AiposWeb, :live_view
  alias Aipos.ReceiptSettings
  alias Aipos.Organizations

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if !user.organization_id do
      {:ok,
       socket
       |> put_flash(:error, "You must belong to an organization to access receipt settings")
       |> redirect(to: ~p"/dashboard")}
    else
      current_organization = Organizations.get_organization!(user.organization_id)
      settings = ReceiptSettings.get_or_create_receipt_settings(current_organization.id)
      changeset = ReceiptSettings.change_receipt_setting(settings)

      socket =
        socket
        |> assign(:current_organization, current_organization)
        |> assign(:settings, settings)
        |> assign(:changeset, changeset)
        |> assign(:form, to_form(changeset))

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"receipt_setting" => params}, socket) do
    changeset =
      socket.assigns.settings
      |> ReceiptSettings.change_receipt_setting(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"receipt_setting" => params}, socket) do
    case ReceiptSettings.update_receipt_setting(socket.assigns.settings, params) do
      {:ok, _settings} ->
        {:noreply,
         socket
         |> put_flash(:info, "Receipt settings updated successfully!")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error updating settings. Please check the form.")
         |> assign(:form, to_form(changeset))}
    end
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
        active_page="receipt_settings"
      />

      <div class="flex-1 pl-64 overflow-auto">
        <div class="mx-auto max-w-6xl py-8 px-4">
          <div class="bg-white shadow-lg rounded-lg overflow-hidden">
            <div class="bg-gradient-to-r from-pink-600 to-purple-800 px-6 py-10 text-white">
              <h1 class="text-3xl font-bold">Receipt Customization</h1>
              <p class="mt-2 text-pink-100">
                Customize how your receipts look and what information they display
              </p>
            </div>

            <div class="p-6">
              <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                  <!-- Left Column: Settings -->
                  <div class="space-y-6">
                    <div>
                      <h3 class="text-lg font-semibold text-gray-900 mb-4">Header Information</h3>
                      <div class="space-y-3">
                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_logo]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_logo]"
                            value="true"
                            checked={@form[:show_logo].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Organization Logo</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_organization_name]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_organization_name]"
                            value="true"
                            checked={@form[:show_organization_name].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Organization Name</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_location]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_location]"
                            value="true"
                            checked={@form[:show_location].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Location/Branch</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_address]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_address]"
                            value="true"
                            checked={@form[:show_address].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Address</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_phone]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_phone]"
                            value="true"
                            checked={@form[:show_phone].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Phone Number</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_email]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_email]"
                            value="true"
                            checked={@form[:show_email].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Email Address</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_kra_pin]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_kra_pin]"
                            value="true"
                            checked={@form[:show_kra_pin].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show KRA PIN/VAT Number</span>
                        </label>
                      </div>
                    </div>

                    <div>
                      <h3 class="text-lg font-semibold text-gray-900 mb-4">
                        Transaction Information
                      </h3>
                      <div class="space-y-3">
                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_cashier]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_cashier]"
                            value="true"
                            checked={@form[:show_cashier].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Cashier Name</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_register]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_register]"
                            value="true"
                            checked={@form[:show_register].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Register/Till</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_customer]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_customer]"
                            value="true"
                            checked={@form[:show_customer].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show Customer Information</span>
                        </label>

                        <label class="flex items-center">
                          <input type="hidden" name="receipt_setting[show_vat_breakdown]" value="false" />
                          <input
                            type="checkbox"
                            name="receipt_setting[show_vat_breakdown]"
                            value="true"
                            checked={@form[:show_vat_breakdown].value}
                            class="rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                          />
                          <span class="ml-3 text-sm text-gray-700">Show VAT Breakdown (16%)</span>
                        </label>
                      </div>
                    </div>

                    <div>
                      <h3 class="text-lg font-semibold text-gray-900 mb-4">Custom Text</h3>
                      <div class="space-y-4">
                        <div>
                          <label class="block text-sm font-medium text-gray-700 mb-1">
                            Header Text (Optional)
                          </label>
                          <textarea
                            name="receipt_setting[header_text]"
                            rows="2"
                            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-pink-500 focus:ring-pink-500 sm:text-sm"
                            placeholder="Welcome to our store!"
                          >{@form[:header_text].value}</textarea>
                          <p class="mt-1 text-xs text-gray-500">
                            Appears at the top of the receipt
                          </p>
                        </div>

                        <div>
                          <label class="block text-sm font-medium text-gray-700 mb-1">
                            Footer Text
                          </label>
                          <textarea
                            name="receipt_setting[footer_text]"
                            rows="3"
                            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-pink-500 focus:ring-pink-500 sm:text-sm"
                          >{@form[:footer_text].value}</textarea>
                          <p class="mt-1 text-xs text-gray-500">
                            Appears at the bottom of the receipt
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                  <!-- Right Column: Preview -->
                  <div>
                    <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                      <span class="mr-2">Live Preview</span>
                      <span class="text-xs font-normal text-gray-500">(Updates as you type)</span>
                    </h3>
                    <div class="border-2 border-dashed border-gray-300 rounded-lg bg-white shadow-sm overflow-hidden">
                      <!-- Receipt Preview -->
                      <div class="p-8 font-mono text-sm space-y-3" style="max-width: 300px; margin: 0 auto;">
                        <!-- Header Text -->
                        <%= if @form[:header_text].value && @form[:header_text].value != "" do %>
                          <div class="text-center border-b border-gray-300 pb-2 mb-2">
                            <p class="text-xs whitespace-pre-line"><%= @form[:header_text].value %></p>
                          </div>
                        <% end %>

                        <!-- Logo -->
                        <%= if @form[:show_logo].value do %>
                          <div class={"text-center mb-2 #{if(@form[:logo_position].value == "left", do: "text-left", else: (if @form[:logo_position].value == "right", do: "text-right", else: "text-center"))}"}>
                            <%= if @current_organization.logo do %>
                              <img src={@current_organization.logo} alt="Logo" class="h-12 inline-block" />
                            <% else %>
                              <div class="text-xs text-gray-400 italic">[Logo will appear here]</div>
                            <% end %>
                          </div>
                        <% end %>

                        <!-- Organization Name -->
                        <%= if @form[:show_organization_name].value do %>
                          <div class="text-center font-bold text-base">
                            <%= @current_organization.name %>
                          </div>
                        <% end %>

                        <!-- Location -->
                        <%= if @form[:show_location].value && @current_organization.location do %>
                          <div class="text-center text-xs">
                            <%= @current_organization.location %>
                          </div>
                        <% end %>

                        <!-- Address -->
                        <%= if @form[:show_address].value do %>
                          <div class="text-center text-xs">
                            <%= @current_organization.address %>
                          </div>
                        <% end %>

                        <!-- Phone -->
                        <%= if @form[:show_phone].value do %>
                          <div class="text-center text-xs">
                            Tel: <%= @current_organization.phone %>
                          </div>
                        <% end %>

                        <!-- Email -->
                        <%= if @form[:show_email].value do %>
                          <div class="text-center text-xs">
                            Email: <%= @current_organization.email %>
                          </div>
                        <% end %>

                        <!-- KRA PIN -->
                        <%= if @form[:show_kra_pin].value && @current_organization.kra_pin do %>
                          <div class="text-center text-xs">
                            PIN: <%= @current_organization.kra_pin %>
                          </div>
                        <% end %>

                        <div class="border-t border-dashed border-gray-400 my-3"></div>

                        <!-- Sample Sale Items -->
                        <div class="text-xs">
                          <div class="font-bold mb-2">SALE RECEIPT #12345</div>
                          <div class="text-xs text-gray-600">
                            Date: <%= DateTime.utc_now() |> Calendar.strftime("%d/%m/%Y %H:%M") %>
                          </div>
                        </div>

                        <%= if @form[:show_cashier].value do %>
                          <div class="text-xs">Cashier: John Doe</div>
                        <% end %>

                        <%= if @form[:show_register].value do %>
                          <div class="text-xs">Register: TILL-001</div>
                        <% end %>

                        <%= if @form[:show_customer].value do %>
                          <div class="text-xs">Customer: Walk-in</div>
                        <% end %>

                        <div class="border-t border-gray-400 my-2"></div>

                        <!-- Sample Items -->
                        <div class="text-xs space-y-1">
                          <div class="flex justify-between">
                            <span>Sample Item 1 x2</span>
                            <span>500.00</span>
                          </div>
                          <div class="flex justify-between">
                            <span>Sample Item 2 x1</span>
                            <span>300.00</span>
                          </div>
                        </div>

                        <div class="border-t border-gray-400 my-2"></div>

                        <!-- VAT Breakdown -->
                        <%= if @form[:show_vat_breakdown].value do %>
                          <div class="text-xs space-y-1">
                            <div class="flex justify-between">
                              <span>Subtotal:</span>
                              <span>689.66</span>
                            </div>
                            <div class="flex justify-between">
                              <span>VAT (16%):</span>
                              <span>110.34</span>
                            </div>
                            <div class="border-t border-gray-300 my-1"></div>
                          </div>
                        <% end %>

                        <div class="flex justify-between font-bold text-sm">
                          <span>TOTAL:</span>
                          <span>KES 800.00</span>
                        </div>

                        <div class="border-t border-gray-400 my-2"></div>

                        <!-- Payment Info -->
                        <div class="text-xs space-y-1">
                          <div class="flex justify-between">
                            <span>Payment:</span>
                            <span>CASH</span>
                          </div>
                          <div class="flex justify-between">
                            <span>Tendered:</span>
                            <span>1000.00</span>
                          </div>
                          <div class="flex justify-between">
                            <span>Change:</span>
                            <span>200.00</span>
                          </div>
                        </div>

                        <!-- Footer Text -->
                        <%= if @form[:footer_text].value && @form[:footer_text].value != "" do %>
                          <div class="border-t border-gray-300 pt-2 mt-3">
                            <p class="text-center text-xs whitespace-pre-line"><%= @form[:footer_text].value %></p>
                          </div>
                        <% end %>

                        <div class="text-center text-xs text-gray-500 mt-3">
                          *** END OF RECEIPT ***
                        </div>
                      </div>
                    </div>
                    
                    <div class="mt-3 text-xs text-gray-600 bg-blue-50 p-3 rounded">
                      <p class="font-semibold text-blue-800">💡 Tip:</p>
                      <p>This preview updates in real-time as you change settings. Click "Save Settings" to apply changes to actual receipts.</p>
                    </div>
                  </div>
                </div>

                <div class="flex items-center justify-end space-x-3 pt-6 border-t border-gray-200">
                  <.link navigate={~p"/dashboard"} class="text-gray-600 hover:text-gray-900">
                    Cancel
                  </.link>
                  <button
                    type="submit"
                    phx-disable-with="Saving..."
                    class="px-6 py-3 bg-gradient-to-r from-pink-600 to-purple-600 text-white font-medium rounded-lg hover:from-pink-700 hover:to-purple-700 transition-colors"
                  >
                    Save Settings
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
