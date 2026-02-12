defmodule Aipos.ReceiptSettings.ReceiptSetting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "receipt_settings" do
    field :show_logo, :boolean, default: true
    field :logo_position, :string, default: "center"  # center, left, right
    field :show_organization_name, :boolean, default: true
    field :show_location, :boolean, default: true
    field :show_address, :boolean, default: true
    field :show_phone, :boolean, default: true
    field :show_email, :boolean, default: false
    field :show_kra_pin, :boolean, default: true
    field :show_vat_breakdown, :boolean, default: true
    field :header_text, :string
    field :footer_text, :string, default: "Thank you for your business!\nGoods once sold are not refundable\nPlease come again"
    field :show_cashier, :boolean, default: true
    field :show_register, :boolean, default: true
    field :show_customer, :boolean, default: true
    
    belongs_to :organization, Aipos.Organizations.Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(receipt_setting, attrs) do
    receipt_setting
    |> cast(attrs, [
      :show_logo,
      :logo_position,
      :show_organization_name,
      :show_location,
      :show_address,
      :show_phone,
      :show_email,
      :show_kra_pin,
      :show_vat_breakdown,
      :header_text,
      :footer_text,
      :show_cashier,
      :show_register,
      :show_customer,
      :organization_id
    ])
    |> validate_required([:organization_id])
    |> validate_inclusion(:logo_position, ["center", "left", "right"])
  end
end
