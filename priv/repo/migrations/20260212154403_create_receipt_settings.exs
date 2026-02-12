defmodule Aipos.Repo.Migrations.CreateReceiptSettings do
  use Ecto.Migration

  def change do
    create table(:receipt_settings) do
      add :show_logo, :boolean, default: true, null: false
      add :logo_position, :string, default: "center", null: false
      add :show_organization_name, :boolean, default: true, null: false
      add :show_location, :boolean, default: true, null: false
      add :show_address, :boolean, default: true, null: false
      add :show_phone, :boolean, default: true, null: false
      add :show_email, :boolean, default: false, null: false
      add :show_kra_pin, :boolean, default: true, null: false
      add :show_vat_breakdown, :boolean, default: true, null: false
      add :header_text, :text
      add :footer_text, :text, default: "Thank you for your business!\\nGoods once sold are not refundable\\nPlease come again"
      add :show_cashier, :boolean, default: true, null: false
      add :show_register, :boolean, default: true, null: false
      add :show_customer, :boolean, default: true, null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:receipt_settings, [:organization_id])
  end
end
