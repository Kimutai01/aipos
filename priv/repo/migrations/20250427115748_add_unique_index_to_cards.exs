defmodule Aipos.Repo.Migrations.AddUniqueIndexToCards do
  use Ecto.Migration

  def change do
    create unique_index(:cards, :card, name: :unique_card_index)
  end
end
