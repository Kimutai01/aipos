defmodule AiposWeb.Router do
  use AiposWeb, :router

  import AiposWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AiposWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :ussd do
    plug :accepts, ["x-www-form-urlencoded"]
  end

  scope "/", AiposWeb do
    pipe_through :browser
  end

  # Other scopes may use custom stacks.
  # scope "/api", AiposWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:aipos, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AiposWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AiposWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{AiposWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/api", AiposWeb do
    pipe_through :api

    post "/iot/card", IotController, :create_card
    post "/iot/status", IotController, :get_product_status
  end

  scope "/", AiposWeb do
    pipe_through :ussd

    post "/ussd", UssdMarketplaceController, :handle_ussd
  end

  scope "/", AiposWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {AiposWeb.UserAuth, :ensure_authenticated},
        {AiposWeb.UserAuth, :mount_current_user}
      ] do
      live "/dashboard", DashboardLive.Index, :index
      live "/manage_users", Users.Staff
      live "/users/staff/new", Users.Staff, :new
      live "/users/staff/:id/edit", Users.Staff, :edit
      live "/start_sale", Live.Sale.Start
      live "/sales", Sale.Sales
      live "/cash_management", CashManagementLive.Index
      # live "/suppliers", SuppliersLive.Index
      live "/suppliers", SupplierLive.Index, :index
      live "/suppliers/new", SupplierLive.Index, :new
      live "/suppliers/:id/edit", SupplierLive.Index, :edit

      live "/suppliers/:id", SupplierLive.Show, :show
      live "/suppliers/:id/show/edit", SupplierLive.Show, :edit
      live "/promotions", PromotionsLive.Index
      # live "/customers", CustomersLive.Index
      live "/customers", CustomerLive.Index, :index
      live "/customers/new", CustomerLive.Index, :new
      live "/customers/:id/edit", CustomerLive.Index, :edit

      live "/customers/:id", CustomerLive.Show, :show
      live "/customers/:id/show/edit", CustomerLive.Show, :edit
      live "/create_organization", OrganizationLive.Create, :index
      live "/organizations", OrganizationLive.Index, :index
      live "/organizations/new", OrganizationLive.Index, :new
      live "/organizations/:id/edit", OrganizationLive.Index, :edit

      live "/organizations/:id", OrganizationLive.Show, :show
      live "/organizations/:id/show/edit", OrganizationLive.Show, :edit

      live "/products", ProductLive.Index, :index
      live "/products/new", ProductLive.Index, :new
      live "/products/:id/edit", ProductLive.Index, :edit

      live "/products/:product_id/skus", ProductSkuLive.Index, :index
      live "/products/:product_id/skus/new", ProductSkuLive.Index, :new
      live "/products/:product_id/skus/:id/edit", ProductSkuLive.Index, :edit

      live "/registers", RegisterLive.Index, :index
      live "/registers/new", RegisterLive.Index, :new
      live "/registers/:id/edit", RegisterLive.Index, :edit

      live "/registers/:id", RegisterLive.Show, :show
      live "/registers/:id/show/edit", RegisterLive.Show, :edit

      live "/products/:id", ProductLive.Show, :show
      live "/products/:id/show/edit", ProductLive.Show, :edit
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", AiposWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{AiposWeb.UserAuth, :mount_current_user}] do
      live "/marketplace", MarketplaceLive.Index

      live "/success", SuccessLive.Index
      live "/self_checkout", Live.SelfCheckout
      live "/", LandingLive.Index
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
