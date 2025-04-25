defmodule Aipos.Repo.Migrations.AddLabelsToProductSku do
  use Ecto.Migration

  def change do
    alter table(:product_skus) do
      add :ai_ingredients, :text
      add :ai_nutritional_info, :text
      add :ai_health_benefits, :text
      add :ai_usage_instructions, :text
      add :ai_additional_info, :text
    end
  end
end
