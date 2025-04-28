defmodule Aipos.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :card, :string
      add :device, :string

      timestamps(type: :utc_datetime)
    end
  end
end
