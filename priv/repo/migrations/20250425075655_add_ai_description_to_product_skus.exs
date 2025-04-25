defmodule Aipos.Repo.Migrations.AddAiDescriptionToProductSkus do
  use Ecto.Migration

  def change do
    alter table(:product_skus) do
      add :ai_description, :string
    end

    create index(:product_skus, [:ai_description])
  end
end
