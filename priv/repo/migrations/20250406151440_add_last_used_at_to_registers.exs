defmodule Aipos.Repo.Migrations.AddLastUsedAtToRegisters do
  use Ecto.Migration

  def change do
    alter table(:registers) do
      add :last_used_at, :utc_datetime
    end

    create index(:registers, [:last_used_at])
  end
end
