defmodule Aipos.Repo.Migrations.AddSubtotalToSale do
  use Ecto.Migration

  def change do
    alter table(:sales) do
      add :subtotal, :decimal
    end

    create index(:sales, [:subtotal])
  end
end
