defmodule AiposWeb.Sidebar do
  use AiposWeb, :live_component

  def render(assigns) do
    ~H"""
    <aside
      id="sidebar-multi-level-sidebar"
      class="fixed top-0 left-0 z-40 w-64 h-screen transition-transform -translate-x-full sm:translate-x-0"
      aria-label="Sidebar"
    >
      <div class="h-full flex flex-col overflow-y-auto bg-gray-800 text-white">
        <div class="p-4 border-b border-gray-700">
          <div class="flex items-center justify-center mb-4">
            <%= if @current_organization && @current_organization.logo do %>
              <img
                src={@current_organization.logo}
                alt="Organization Logo"
                class="h-16 w-16 object-contain rounded-full bg-white p-1"
              />
            <% else %>
              <div class="h-16 w-16 rounded-full bg-blue-600 flex items-center justify-center text-2xl font-bold">
                <%= if @current_organization && @current_organization.name do %>
                  {String.first(@current_organization.name)}
                <% else %>
                  S
                <% end %>
              </div>
            <% end %>
          </div>
          <div class="text-center">
            <h2 class="text-xl font-bold truncate">
              <%= if @current_organization do %>
                {@current_organization.name}
              <% else %>
                SmartCheckout
              <% end %>
            </h2>
            <p class="text-sm text-gray-400">POS System</p>
          </div>
        </div>
        
    <!-- Navigation Links -->
        <div class="flex-grow py-4">
          <p class="px-4 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
            Main Menu
          </p>
          <ul class="space-y-1">
            <li>
              <a
                href="/dashboard"
                class={
                  active_class(
                    @active_page == "dashboard",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="home" type="solid" class="h-5 w-5 mr-3 text-blue-400" />
                <span>Dashboard</span>
              </a>
            </li>

            <li>
              <a
                href="/start_sale"
                class={
                  active_class(
                    @active_page == "new_session",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="play" type="solid" class="h-5 w-5 mr-3 text-green-400" />
                <span>Start Sale Session</span>
              </a>
            </li>
            <!-- Add this after the "Inventory" item and before the "Management" section -->
            <li>
              <a
                href="/customers"
                class={
                  active_class(
                    @active_page == "customers",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="user-group" type="solid" class="h-5 w-5 mr-3 text-teal-400" />
                <span>Customers</span>
              </a>
            </li>

            <li>
              <a
                href="/promotions"
                class={
                  active_class(
                    @active_page == "promotions",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="gift" type="solid" class="h-5 w-5 mr-3 text-amber-400" />
                <span>Promotions</span>
              </a>
            </li>

            <li>
              <a
                href="/suppliers"
                class={
                  active_class(
                    @active_page == "suppliers",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="truck" type="solid" class="h-8 w- mr-3 text-emerald-400" />
                <span>Suppliers</span>
              </a>
            </li>

            <li>
              <a
                href="/cash_management"
                class={
                  active_class(
                    @active_page == "cash_management",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="banknotes" type="solid" class="h-5 w-5 mr-3 text-green-400" />
                <span>Cash Management</span>
              </a>
            </li>

            <li>
              <a
                href="/sales"
                class={
                  active_class(
                    @active_page == "sales",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon
                  name="shopping-cart"
                  type="solid"
                  class="h-5 w-5 mr-3 text-yellow-400"
                />
                <span>Sales</span>
              </a>
            </li>

            <li>
              <a
                href="/products"
                class={
                  active_class(
                    @active_page == "products",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="cube" type="solid" class="h-5 w-5 mr-3 text-purple-400" />
                <span>Products</span>
              </a>
            </li>

            <li>
              <a
                href="/inventory"
                class={
                  active_class(
                    @active_page == "inventory",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon
                  name="clipboard-document-list"
                  type="solid"
                  class="h-5 w-5 mr-3 text-pink-400"
                />
                <span>Inventory</span>
              </a>
            </li>
          </ul>

          <p class="px-4 text-xs font-semibold text-gray-400 uppercase tracking-wider mt-6 mb-2">
            Management
          </p>
          <ul class="space-y-1">
            <li>
              <a
                href="/manage_users"
                class={
                  active_class(
                    @active_page == "users",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="users" type="solid" class="h-5 w-5 mr-3 text-indigo-400" />
                <span>Staff</span>
              </a>
            </li>

            <li>
              <a
                href="/reports"
                class={
                  active_class(
                    @active_page == "reports",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="chart-bar" type="solid" class="h-5 w-5 mr-3 text-red-400" />
                <span>Reports</span>
              </a>
            </li>

            <%!-- registers --%>

            <li>
              <a
                href="/registers"
                class={
                  active_class(
                    @active_page == "registers",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon
                  name="computer-desktop"
                  type="solid"
                  class="h-5 w-5 mr-3 text-gray-400"
                />
                <span>Registers</span>
              </a>
            </li>

            <li>
              <a
                href="/settings"
                class={
                  active_class(
                    @active_page == "settings",
                    "flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg"
                  )
                }
              >
                <Heroicons.icon name="cog-6-tooth" type="solid" class="h-5 w-5 mr-3 text-gray-400" />
                <span>Settings</span>
              </a>
            </li>
          </ul>
        </div>
        
    <!-- User Profile & Logout -->
        <div class="p-4 border-t border-gray-700">
          <div class="flex items-center mb-4">
            <div class="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-lg font-medium mr-3">
              {String.first(@current_user.email || "U")}
            </div>
            <div>
              <p class="font-medium">{@current_user.email}</p>
              <p class="text-xs text-gray-400">Admin</p>
            </div>
          </div>
          <a
            href="/users/log_out"
            class="flex items-center py-2 px-4 text-white hover:bg-gray-700 rounded-lg w-full"
          >
            <Heroicons.icon
              name="arrow-right-on-rectangle"
              type="solid"
              class="h-5 w-5 mr-3 text-red-400"
            />
            <span>Sign Out</span>
          </a>
        </div>
      </div>
    </aside>
    """
  end

  # Helper function to apply active styles
  defp active_class(true, base_class), do: "#{base_class} bg-gray-700 font-medium"
  defp active_class(false, base_class), do: base_class
end
