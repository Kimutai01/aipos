defmodule AiposWeb.Components.SkuAiInfo do
  use Phoenix.Component
  import AiposWeb.CoreComponents

  def sku_ai_info(assigns) do
    # Parse JSON strings to Elixir data structures
    assigns =
      assigns
      |> assign_new(:ingredients, fn ->
        case Jason.decode(assigns.sku.ai_ingredients || "[]") do
          {:ok, ingredients} -> ingredients
          _ -> []
        end
      end)
      |> assign_new(:nutritional_info, fn ->
        case Jason.decode(assigns.sku.ai_nutritional_info || "{}") do
          {:ok, info} -> info
          _ -> %{}
        end
      end)
      |> assign_new(:health_benefits, fn ->
        case Jason.decode(assigns.sku.ai_health_benefits || "[]") do
          {:ok, benefits} -> benefits
          _ -> []
        end
      end)
      |> assign_new(:show_info, fn -> false end)

    ~H"""
    <div class="bg-white shadow rounded-lg mb-6 overflow-hidden">
      <div class="px-4 py-3 bg-gradient-to-r from-blue-50 to-indigo-50 flex justify-between items-center">
        <div>
          <h3 class="text-md font-semibold leading-6 text-gray-900 flex items-center">
            <Heroicons.icon name="sparkles" class="h-4 w-4 mr-2 text-blue-500" />
            AI Analysis: {@sku.name}
          </h3>
        </div>
        <button
          type="button"
          phx-click="toggle_ai_info"
          phx-value-id={@sku.id}
          class="inline-flex items-center text-sm text-blue-600 hover:text-blue-800"
        >
          <span class="mr-1">{if @show_info, do: "Hide details", else: "Show details"}</span>
          <Heroicons.icon
            name="chevron-down"
            class={"h-4 w-4 transform #{if @show_info, do: "rotate-180", else: ""}"}
          />
        </button>
      </div>

      <div class={"border-t border-gray-100 #{if !@show_info, do: "hidden"}"}>
        <div class="px-4 py-4 sm:p-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Ingredients -->
            <div>
              <h4 class="text-sm font-medium text-gray-900 mb-2">Ingredients</h4>
              <%= if length(@ingredients) > 0 do %>
                <ul class="list-disc pl-5 text-sm text-gray-600 space-y-1">
                  <%= for ingredient <- @ingredients do %>
                    <li>{ingredient}</li>
                  <% end %>
                </ul>
              <% else %>
                <p class="text-sm text-gray-500 italic">No ingredient information available</p>
              <% end %>
            </div>
            
    <!-- Nutritional Information -->
            <div>
              <h4 class="text-sm font-medium text-gray-900 mb-2">Nutritional Information</h4>
              <%= if map_size(@nutritional_info) > 0 do %>
                <div class="grid grid-cols-2 gap-x-4 gap-y-2">
                  <%= if Map.has_key?(@nutritional_info, "calories") do %>
                    <div class="flex flex-col">
                      <span class="text-xs text-gray-500">Calories</span>
                      <span class="text-sm font-medium">{@nutritional_info["calories"]}</span>
                    </div>
                  <% end %>
                  <%= if Map.has_key?(@nutritional_info, "protein") do %>
                    <div class="flex flex-col">
                      <span class="text-xs text-gray-500">Protein</span>
                      <span class="text-sm font-medium">{@nutritional_info["protein"]}</span>
                    </div>
                  <% end %>
                  <%= if Map.has_key?(@nutritional_info, "carbs") do %>
                    <div class="flex flex-col">
                      <span class="text-xs text-gray-500">Carbohydrates</span>
                      <span class="text-sm font-medium">{@nutritional_info["carbs"]}</span>
                    </div>
                  <% end %>
                  <%= if Map.has_key?(@nutritional_info, "fat") do %>
                    <div class="flex flex-col">
                      <span class="text-xs text-gray-500">Fat</span>
                      <span class="text-sm font-medium">{@nutritional_info["fat"]}</span>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <p class="text-sm text-gray-500 italic">No nutritional information available</p>
              <% end %>
            </div>
          </div>
          
    <!-- Usage Instructions -->
          <%= if @sku.ai_usage_instructions && @sku.ai_usage_instructions != "" do %>
            <div class="mt-4">
              <h4 class="text-sm font-medium text-gray-900 mb-2">How to Use</h4>
              <p class="text-sm text-gray-600">{@sku.ai_usage_instructions}</p>
            </div>
          <% end %>
          
    <!-- Health Benefits -->
          <%= if length(@health_benefits) > 0 do %>
            <div class="mt-4">
              <h4 class="text-sm font-medium text-gray-900 mb-2">Health Benefits</h4>
              <ul class="list-disc pl-5 text-sm text-gray-600 space-y-1">
                <%= for benefit <- @health_benefits do %>
                  <li>{benefit}</li>
                <% end %>
              </ul>
            </div>
          <% end %>
          
    <!-- Additional Information -->
          <%= if @sku.ai_additional_info && @sku.ai_additional_info != "" do %>
            <div class="mt-4">
              <h4 class="text-sm font-medium text-gray-900 mb-2">Additional Information</h4>
              <p class="text-sm text-gray-600">{@sku.ai_additional_info}</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
