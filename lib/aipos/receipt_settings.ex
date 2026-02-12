defmodule Aipos.ReceiptSettings do
  @moduledoc """
  The ReceiptSettings context.
  """

  import Ecto.Query, warn: false
  alias Aipos.Repo
  alias Aipos.ReceiptSettings.ReceiptSetting

  @doc """
  Gets receipt settings for an organization, creates default if none exists.
  """
  def get_or_create_receipt_settings(organization_id) do
    case Repo.get_by(ReceiptSetting, organization_id: organization_id) do
      nil ->
        # Create with explicit defaults to ensure all fields are set
        default_attrs = %{
          organization_id: organization_id,
          show_logo: true,
          logo_position: "center",
          show_organization_name: true,
          show_location: true,
          show_address: true,
          show_phone: true,
          show_email: false,
          show_kra_pin: true,
          show_vat_breakdown: true,
          show_cashier: true,
          show_register: true,
          show_customer: true,
          footer_text: "Thank you for your business!\nGoods once sold are not refundable\nPlease come again"
        }
        
        case create_receipt_setting(default_attrs) do
          {:ok, settings} -> settings
          {:error, _} -> 
            # If creation fails, return a struct with defaults (won't be persisted)
            %ReceiptSetting{
              organization_id: organization_id,
              show_logo: true,
              logo_position: "center",
              show_organization_name: true,
              show_location: true,
              show_address: true,
              show_phone: true,
              show_email: false,
              show_kra_pin: true,
              show_vat_breakdown: true,
              show_cashier: true,
              show_register: true,
              show_customer: true,
              footer_text: "Thank you for your business!\nGoods once sold are not refundable\nPlease come again"
            }
        end
        
      settings ->
        settings
    end
  end

  @doc """
  Gets a single receipt_setting.
  """
  def get_receipt_setting!(id), do: Repo.get!(ReceiptSetting, id)

  @doc """
  Creates a receipt_setting.
  """
  def create_receipt_setting(attrs \\ %{}) do
    %ReceiptSetting{}
    |> ReceiptSetting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a receipt_setting.
  """
  def update_receipt_setting(%ReceiptSetting{} = receipt_setting, attrs) do
    receipt_setting
    |> ReceiptSetting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking receipt_setting changes.
  """
  def change_receipt_setting(%ReceiptSetting{} = receipt_setting, attrs \\ %{}) do
    ReceiptSetting.changeset(receipt_setting, attrs)
  end
end
