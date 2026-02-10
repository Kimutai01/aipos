# AIPOS - AI-Powered Point of Sale System

AIPOS is a modern, intelligent Point of Sale (POS) system designed for retail shops, combining traditional POS functionality with AI-powered product insights and seamless payment processing.

## 🚀 Features

### For Shop Owners & Staff

#### 📊 Sales Management
- **Real-time POS Interface** - Fast, intuitive checkout experience
- **Multiple Payment Methods** - Cash, M-Pesa, and Card payments via Paystack
- **Barcode Scanning** - Support for both external scanners and manual entry
- **Product Search** - Quick product lookup by name or barcode
- **Register Management** - Multiple register support with status tracking
- **Customer Management** - Track customer information and purchase history

#### 📈 Analytics & Reporting
- **Sales Analytics** - View revenue trends, payment method breakdowns
- **Product Performance** - Track best-selling items and inventory levels
- **Staff Performance** - Monitor cashier activity and sales metrics
- **Cash Management** - Track drawer status and cash flow
- **Real-time Dashboard** - Live updates on sales and inventory

#### 🤖 AI-Powered Insights
- **Product Information** - AI-generated ingredient lists and nutritional info
- **Health Benefits** - Automatically generated health information
- **Usage Instructions** - Smart product usage recommendations
- **Additional Details** - Comprehensive product descriptions

#### 👥 User Management
- **Staff Accounts** - Create and manage cashier accounts
- **Role-Based Access** - Control permissions by user role
- **Organization Management** - Multi-organization support
- **Supplier Management** - Track suppliers and purchase orders

### For Customers

#### 🛒 Self-Checkout Experience
- **Easy Self-Service** - Scan and pay without cashier assistance
- **Product Search** - Browse and search products independently
- **Multiple Payment Options** - M-Pesa and Card payments
- **Digital Receipts** - Instant receipt generation
- **Product Information** - View detailed product info while shopping:
  - Ingredients
  - Nutritional information
  - Health benefits
  - Usage instructions

## 🛠 Technology Stack

- **Backend:** Elixir/Phoenix Framework
- **Frontend:** Phoenix LiveView for real-time interactivity
- **Database:** PostgreSQL
- **Payments:** Paystack integration (M-Pesa & Card)
- **AI Integration:** Product information enhancement
- **Authentication:** Built-in user authentication system

## 📦 Installation

### Prerequisites

- Elixir 1.14 or higher
- Erlang/OTP 25 or higher
- PostgreSQL 12 or higher
- Node.js 14 or higher (for asset compilation)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aipos
   ```

2. **Install dependencies**
   ```bash
   mix setup
   ```
   This will:
   - Install Elixir dependencies
   - Create and migrate the database
   - Install Node.js dependencies
   - Build assets

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   Update with your configuration:
   - Database credentials
   - Paystack API keys
   - Other application secrets

4. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```
   Or inside IEx for interactive development:
   ```bash
   iex -S mix phx.server
   ```

5. **Visit the application**
   - Main app: [`http://localhost:4000`](http://localhost:4000)
   - Self-checkout: [`http://localhost:4000/self_checkout`](http://localhost:4000/self_checkout)
   - Dashboard: [`http://localhost:4000/dashboard`](http://localhost:4000/dashboard)

## 🔧 Configuration

### Payment Integration (Paystack)

1. Get your Paystack API keys from [Paystack Dashboard](https://dashboard.paystack.com)
2. Set environment variables:
   ```bash
   export PAYSTACK_SECRET_KEY="sk_test_your_key_here"  # For testing
   export PAYSTACK_SECRET_KEY="sk_live_your_key_here"  # For production
   ```
3. Configure webhook URL in Paystack dashboard:
   ```
   https://your-domain.com/api/paystack/webhook
   ```

See [PAYSTACK_INTEGRATION.md](PAYSTACK_INTEGRATION.md) for detailed payment setup.

### Database Configuration

Update `config/dev.exs` or set `DATABASE_URL` environment variable:
```bash
export DATABASE_URL="postgresql://user:password@localhost/aipos_dev"
```

## 📱 Usage

### For Shop Staff

1. **Log in** with your staff credentials
2. **Select a register** to start a sale session
3. **Scan or search** for products
4. **Add items** to cart and adjust quantities
5. **Add customer** information (optional)
6. **Select payment method** and complete sale
7. **View analytics** on the dashboard

### For Customers (Self-Checkout)

1. **Navigate** to `/self_checkout`
2. **Scan or search** for products
3. **Review cart** and product information
4. **Proceed to payment**
5. **Complete payment** via M-Pesa or Card
6. **Receive digital receipt**

## 🏗 Project Structure

```
aipos/
├── lib/
│   ├── aipos/              # Business logic
│   │   ├── accounts/       # User management
│   │   ├── products/       # Product management
│   │   ├── sales/          # Sales and transactions
│   │   ├── customers/      # Customer management
│   │   ├── registers/      # POS register management
│   │   └── paystack.ex     # Payment integration
│   ├── aipos_web/          # Web layer
│   │   ├── live/           # LiveView components
│   │   │   ├── sale/       # POS interface
│   │   │   ├── self_checkout.ex
│   │   │   └── dashboard_live/
│   │   ├── controllers/    # HTTP controllers
│   │   └── components/     # Reusable UI components
├── priv/
│   ├── repo/migrations/    # Database migrations
│   └── static/             # Static assets
├── config/                 # Configuration files
└── test/                   # Test files
```

## 🧪 Testing

Run the test suite:
```bash
mix test
```

Run tests with coverage:
```bash
mix test --cover
```

## 📚 Documentation

- [Paystack Integration Guide](PAYSTACK_INTEGRATION.md) - Complete payment setup
- [Deployment Checklist](DEPLOYMENT_CHECKLIST.md) - Production deployment guide
- [Implementation Summary](PAYSTACK_IMPLEMENTATION_SUMMARY.md) - Technical details

## 🚀 Deployment

### Production Deployment

1. **Set environment variables:**
   ```bash
   export SECRET_KEY_BASE="your-secret-key"
   export DATABASE_URL="postgresql://..."
   export PHX_HOST="pos.kiprotichkimutai.dev"
   export PAYSTACK_SECRET_KEY="sk_live_..."
   ```

2. **Run migrations:**
   ```bash
   mix ecto.migrate
   ```

3. **Build assets:**
   ```bash
   mix assets.deploy
   ```

4. **Start the server:**
   ```bash
   PHX_SERVER=true mix phx.server
   ```

See [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) for complete deployment instructions.

## 🔐 Security

- User authentication with bcrypt password hashing
- CSRF protection on all forms
- Secure session management
- HTTPS required for production
- Webhook signature verification (recommended)
- Role-based access control

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

[Add your license here]

## 💬 Support

For support and questions:
- Create an issue on GitHub
- Contact: [your-email@example.com]

## 🙏 Acknowledgments

- Built with [Phoenix Framework](https://www.phoenixframework.org/)
- Payment processing by [Paystack](https://paystack.com/)
- UI components by [Heroicons](https://heroicons.com/)

---

**AIPOS** - Empowering retail with intelligent point of sale solutions.