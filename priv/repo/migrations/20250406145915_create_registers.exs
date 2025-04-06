defmodule Aipos.Repo.Migrations.CreateRegisters do
  use Ecto.Migration

  def change do
    create table(:registers) do
      add :name, :string
      add :status, :string
      add :organization_id, references(:organizations, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:registers, [:organization_id])
  end
end
