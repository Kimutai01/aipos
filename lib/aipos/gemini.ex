defmodule Aipos.Gemini do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://generativelanguage.googleapis.com"
  plug Tesla.Middleware.JSON

  @gemini_text_model "gemini-2.0-flash"
  @gemini_vision_model "gemini-2.0-flash-exp-image-generation"

  def enrich_product_info(product_name, description, image \\ nil) do
    api_key = "AIzaSyDXxJhHSBBsmMQT7Z5al8c2XOfJS3qoI08"

    fetch_product_details(api_key, product_name, description, image)
  end

  defp fetch_product_details(api_key, product_name, description, image) do
    prompt = build_prompt(product_name, description)

    {model, content} =
      if is_nil(image) || image == "" do
        {@gemini_text_model,
         [
           %{
             "parts" => [
               %{"text" => prompt}
             ]
           }
         ]}
      else
        image_data = read_and_encode_local_image(image)

        if is_nil(image_data) do
          {@gemini_text_model,
           [
             %{
               "parts" => [
                 %{"text" => prompt}
               ]
             }
           ]}
        else
          {@gemini_vision_model,
           [
             %{
               "parts" => [
                 %{"text" => prompt},
                 %{
                   "inline_data" => %{
                     "mime_type" => get_mime_type(image),
                     "data" => image_data
                   }
                 }
               ]
             }
           ]}
        end
      end

    case post(
           "/v1beta/models/#{model}:generateContent?key=#{api_key}",
           %{
             "contents" => content,
             "generationConfig" => %{
               "temperature" => 0.2,
               "maxOutputTokens" => 1024,
               "topP" => 0.95,
               "topK" => 40
             }
           },
           opts: [adapter: [timeout: :infinity, recv_timeout: :infinity]]
         ) do
      {:ok, %{status: 200, body: body}} ->
        parse_gemini_response(body)

      {:ok, %{status: status, body: body}} ->
        {:error, "Gemini API error: Status #{status}, #{inspect(body)}"}

      {:error, error} ->
        {:error, "Request error: #{inspect(error)}"}
    end
  end

  defp build_prompt(product_name, description) do
    """
    Analyze this product and provide detailed, factual information in clean JSON format:

    Product: #{product_name}
    Description: #{description}

    Return a JSON object with these fields:
    - ingredients: List of specific ingredients if applicable
    - nutritionalInfo: For food products, include exact values (not approximations):
      * calories: Exact calorie count per 100g (e.g., "534 kcal")
      * protein: Exact protein content per 100g (e.g., "7.5g")
      * carbs: Exact carbohydrate content per 100g (e.g., "59.2g")
      * fat: Exact fat content per 100g (e.g., "31.8g")
    - healthBenefits: Any specific health benefits associated with the product
    - usageInstructions: Detailed instructions on how to use the product
    - additionalInfo: Any other relevant information (allergens, storage instructions, etc.)

    If any field is not applicable, use null for that field.
    If nutritional information is not known exactly, make educated estimates based on similar products.

    IMPORTANT: Return ONLY the raw JSON object. Do not include markdown code blocks, backticks, or any other text.
    """
  end

  defp read_and_encode_local_image(image_path) do
    full_path =
      if String.starts_with?(image_path, "/uploads") do
        Path.join([Application.app_dir(:aipos, "priv/static"), image_path])
      else
        image_path
      end

    case File.read(full_path) do
      {:ok, binary} ->
        Base.encode64(binary)

      {:error, reason} ->
        require Logger
        Logger.error("Failed to read image at #{full_path}: #{inspect(reason)}")
        nil
    end
  end

  defp get_mime_type(filename) do
    case Path.extname(filename) |> String.downcase() do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".webp" -> "image/webp"
      _ -> "image/jpeg"
    end
  end

  defp parse_gemini_response(response) do
    try do
      case response do
        %{"candidates" => [%{"content" => %{"parts" => parts}} | _]} ->
          text =
            Enum.find_value(parts, "", fn
              %{"text" => text} -> text
              _ -> nil
            end)

          if text && text != "" do
            clean_text =
              text
              |> String.replace(~r/```json\s*/, "")
              |> String.replace(~r/```\s*$/, "")
              |> String.trim()

            Jason.decode(clean_text)
          else
            {:error, "No text content in response"}
          end

        _ ->
          {:error, "Unexpected response format: #{inspect(response)}"}
      end
    rescue
      e ->
        {:error, "Failed to parse Gemini response: #{inspect(e)} with text: #{inspect(response)}"}
    end
  end

  def update_product_with_ai_info(product_id, name, description, image_path) do
    with {:ok, ai_info} <- enrich_product_info(name, description, image_path) do
      ai_data = %{
        ai_ingredients: Jason.encode!(ai_info["ingredients"] || []),
        ai_nutritional_info: Jason.encode!(ai_info["nutritionalInfo"] || %{}),
        ai_health_benefits: Jason.encode!(ai_info["healthBenefits"] || []),
        ai_usage_instructions: ai_info["usageInstructions"] || "",
        ai_additional_info: ai_info["additionalInfo"] || ""
      }

      Aipos.ProductSkus.update_product_ai_info(product_id, ai_data)
    else
      {:error, reason} ->
        require Logger
        Logger.error("Failed to get AI product info: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def list_available_models do
    api_key = "AIzaSyDXxJhHSBBsmMQT7Z5al8c2XOfJS3qoI08"

    case get("/v1beta/models?key=#{api_key}") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, "Error listing models: Status #{status}, #{inspect(body)}"}

      {:error, error} ->
        {:error, "Request error: #{inspect(error)}"}
    end
  end
end
