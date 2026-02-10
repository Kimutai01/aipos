# In your project's priv/repo/seeds.exs file

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This script ensures we have test data including users, organizations,
# products, SKUs, and registers with images.

alias Aipos.Repo
alias Aipos.Accounts.User
alias Aipos.Organizations.Organization
alias Aipos.Products.Product
alias Aipos.ProductSkus.ProductSku
alias Aipos.Sales.Sale
alias Aipos.Sales.SaleItem
alias Aipos.Registers.Register

require Logger

# Initialize HTTPClient for image downloads
# Commented out since we're using placeholder images instead of downloading
# Application.ensure_all_started(:inets)
# Application.ensure_all_started(:ssl)

# ============================================================================
# Helper Functions as Variables
# ============================================================================

# Function to download an image from a URL and save it locally
# Commented out since we're using placeholder images for faster seeding
# download_and_save_image = fn url, prefix ->
#   # Create the uploads directory if it doesn't exist
#   uploads_dir = Path.join(["priv", "static", "uploads"])
#   File.mkdir_p!(uploads_dir)
#
#   # Generate a unique filename
#   filename = "#{prefix}_#{:rand.uniform(100_000)}_#{Path.basename(url)}"
#   # If the URL doesn't end with a recognizable extension, add .jpg
#   filename = if Path.extname(filename) == "", do: "#{filename}.jpg", else: filename
#
#   dest = Path.join(uploads_dir, filename)
#
#   # Download the image
#   case :httpc.request(:get, {String.to_charlist(url), []}, [], body_format: :binary) do
#     {:ok, {{_, 200, _}, _, body}} ->
#       # Save the image to the uploads directory
#       File.write!(dest, body)
#       {:ok, "/uploads/#{filename}"}
#
#     error ->
#       Logger.error("Failed to download image from #{url}: #{inspect(error)}")
#       # Return a default image path
#       {:error, "Failed to download image"}
#   end
# end

# Helper to safely download an image and provide a fallback
# Modified to skip download and use placeholders directly for faster seeding
safe_download_image = fn
  _url, _prefix, nil ->
    nil

  _url, _prefix, fallback ->
    fallback
end

# ============================================================================
# Main Seeding Logic
# ============================================================================

# Clear existing data (be careful with this in production!)
# We need to delete dependent records first to avoid foreign key violations
Logger.info("Cleaning up existing data...")

# Delete sale_items first since they reference product_skus
Repo.delete_all(SaleItem)
# Then delete sales
Repo.delete_all(Sale)
# Then delete registers
Repo.delete_all(Register)
# Now we can safely delete product-related data
Repo.delete_all(ProductSku)
Repo.delete_all(Product)
Repo.delete_all(Organization)
# Don't delete all users, just create new ones for seeding
# Repo.delete_all(User)

Logger.info("Seeding database...")

# ============================================================================
# Create Admin and Regular Users
# ============================================================================

# Create admin users
admin1 =
  %User{}
  |> User.registration_changeset(%{
    email: "admin@example.com",
    password: "Password123!",
    first_name: "Admin",
    last_name: "User",
    role: "admin",
    is_active: true
  })
  |> Repo.insert!()

admin2 =
  %User{}
  |> User.registration_changeset(%{
    email: "manager@example.com",
    password: "Password123!",
    first_name: "Manager",
    last_name: "User",
    role: "admin",
    is_active: true
  })
  |> Repo.insert!()

# Create regular users with password "password"
kim =
  %User{}
  |> User.registration_changeset(%{
    email: "kim@gmail.com",
    password: "password",
    first_name: "Kim",
    last_name: "Smith",
    role: "user",
    is_active: true
  })
  |> Repo.insert!()

mike =
  %User{}
  |> User.registration_changeset(%{
    email: "mike@gmail.com",
    password: "password",
    first_name: "Mike",
    last_name: "Johnson",
    role: "user",
    is_active: true
  })
  |> Repo.insert!()

kevin =
  %User{}
  |> User.registration_changeset(%{
    email: "kevin@gmail.com",
    password: "password",
    first_name: "Kevin",
    last_name: "Williams",
    role: "user",
    is_active: true
  })
  |> Repo.insert!()

Logger.info("Created users")

# ============================================================================
# Create Organizations
# ============================================================================

# Default fallback image paths
default_org_logo = "/images/default_logo.png"
default_product_image = "/images/default_product.png"
default_sku_image = "/images/default_sku.png"

# Download and save organization logos
tech_store_logo =
  safe_download_image.(
    "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1200px-Apple_logo_black.svg.png",
    "org",
    default_org_logo
  )

clothing_store_logo =
  safe_download_image.(
    "https://1000logos.net/wp-content/uploads/2016/09/Zara-Logo.png",
    "org",
    default_org_logo
  )

electronics_store_logo =
  safe_download_image.(
    "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Best_Buy_Logo.svg/1280px-Best_Buy_Logo.svg.png",
    "org",
    default_org_logo
  )

furniture_store_logo =
  safe_download_image.(
    "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Ikea_logo.svg/2560px-Ikea_logo.svg.png",
    "org",
    default_org_logo
  )

grocery_store_logo =
  safe_download_image.(
    "https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Walmart_logo.svg/2560px-Walmart_logo.svg.png",
    "org",
    default_org_logo
  )

# Create organizations - first the main ones from the original script
tech_store =
  %Organization{}
  |> Organization.changeset(%{
    name: "TechHub",
    address: "123 Silicon Valley, CA 94043",
    phone: "+1 (555) 123-4567",
    email: "contact@techhub.com",
    logo: tech_store_logo,
    description: "Premier destination for the latest in technology and gadgets",
    created_by_id: admin1.id
  })
  |> Repo.insert!()

clothing_store =
  %Organization{}
  |> Organization.changeset(%{
    name: "FashionForward",
    address: "456 Fashion Ave, NY 10018",
    phone: "+1 (555) 987-6543",
    email: "info@fashionforward.com",
    logo: clothing_store_logo,
    description: "Contemporary fashion retailer offering trendy clothing options",
    created_by_id: admin2.id
  })
  |> Repo.insert!()

# Now create organizations for each user
kim_org =
  %Organization{}
  |> Organization.changeset(%{
    name: "Kim's Electronics",
    address: "789 Tech Blvd, San Jose, CA 95113",
    phone: "+1 (555) 234-5678",
    email: "kim@kims-electronics.com",
    logo: electronics_store_logo,
    description: "Specialty electronics store focusing on high-end consumer tech",
    created_by_id: kim.id
  })
  |> Repo.insert!()

mike_org =
  %Organization{}
  |> Organization.changeset(%{
    name: "Mike's Furniture",
    address: "321 Home St, Minneapolis, MN 55401",
    phone: "+1 (555) 345-6789",
    email: "mike@mikes-furniture.com",
    logo: furniture_store_logo,
    description: "Modern furniture and home decor for contemporary living",
    created_by_id: mike.id
  })
  |> Repo.insert!()

kevin_org =
  %Organization{}
  |> Organization.changeset(%{
    name: "Kevin's Groceries",
    address: "555 Market St, Chicago, IL 60601",
    phone: "+1 (555) 456-7890",
    email: "kevin@kevins-groceries.com",
    logo: grocery_store_logo,
    description: "Fresh local produce and specialty grocery items",
    created_by_id: kevin.id
  })
  |> Repo.insert!()

# Update user associations with their organizations
# This requires you to have a mechanism for associating users with organizations
# The exact implementation depends on your schema, but here's a conceptual example:

# Associate users with organizations if you have a join table or direct association
# This is a placeholder for the actual implementation based on your schema

Logger.info("Created organizations and associated with users")

# ============================================================================
# Create Registers for Each User
# ============================================================================

# Create 4 registers for each user
Logger.info("Creating registers...")

# Admin1 registers for tech store
[
  %{name: "Main Checkout 1", user: admin1, organization: tech_store},
  %{name: "Main Checkout 2", user: admin1, organization: tech_store},
  %{name: "Customer Service", user: admin1, organization: tech_store},
  %{name: "Express Lane", user: admin1, organization: tech_store}
]
|> Enum.each(fn register_data ->
  %Register{}
  |> Register.changeset(%{
    name: register_data.name,
    status: "available",
    organization_id: register_data.organization.id,
    last_used_at: DateTime.truncate(DateTime.utc_now(), :second)
  })
  |> Repo.insert!()
end)

# Admin2 registers for clothing store
[
  %{name: "Front Desk 1", user: admin2, organization: clothing_store},
  %{name: "Front Desk 2", user: admin2, organization: clothing_store},
  %{name: "Returns Counter", user: admin2, organization: clothing_store},
  %{name: "VIP Services", user: admin2, organization: clothing_store}
]
|> Enum.each(fn register_data ->
  %Register{}
  |> Register.changeset(%{
    name: register_data.name,
    status: "available",
    organization_id: register_data.organization.id,
    last_used_at: DateTime.truncate(DateTime.utc_now(), :second)
  })
  |> Repo.insert!()
end)

# Kim's registers for Kim's own organization
[
  %{name: "Kim's POS 1", user: kim, organization: kim_org},
  %{name: "Kim's POS 2", user: kim, organization: kim_org},
  %{name: "Kim's Mobile 1", user: kim, organization: kim_org},
  %{name: "Kim's Mobile 2", user: kim, organization: kim_org}
]
|> Enum.each(fn register_data ->
  %Register{}
  |> Register.changeset(%{
    name: register_data.name,
    status: "available",
    organization_id: register_data.organization.id,
    last_used_at: DateTime.truncate(DateTime.utc_now(), :second)
  })
  |> Repo.insert!()
end)

# Mike's registers for Mike's own organization
[
  %{name: "Mike's POS 1", user: mike, organization: mike_org},
  %{name: "Mike's POS 2", user: mike, organization: mike_org},
  %{name: "Mike's Mobile 1", user: mike, organization: mike_org},
  %{name: "Mike's Mobile 2", user: mike, organization: mike_org}
]
|> Enum.each(fn register_data ->
  %Register{}
  |> Register.changeset(%{
    name: register_data.name,
    status: "available",
    organization_id: register_data.organization.id,
    last_used_at: DateTime.truncate(DateTime.utc_now(), :second)
  })
  |> Repo.insert!()
end)

# Kevin's registers for Kevin's own organization
[
  %{name: "Kevin's POS 1", user: kevin, organization: kevin_org},
  %{name: "Kevin's POS 2", user: kevin, organization: kevin_org},
  %{name: "Kevin's Mobile 1", user: kevin, organization: kevin_org},
  %{name: "Kevin's Mobile 2", user: kevin, organization: kevin_org}
]
|> Enum.each(fn register_data ->
  %Register{}
  |> Register.changeset(%{
    name: register_data.name,
    status: "available",
    organization_id: register_data.organization.id,
    last_used_at: DateTime.truncate(DateTime.utc_now(), :second)
  })
  |> Repo.insert!()
end)

Logger.info("Created registers for all users")

# ============================================================================
# Create Tech Store Products and SKUs
# ============================================================================

# Create products for TechHub
# iPhone product
iphone_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-15-pro-finish-select-202309-6-7inch-naturaltitanium?wid=5120&hei=2880&fmt=p-jpg&qlt=80&.v=1692845702708",
    "product",
    default_product_image
  )

iphone =
  %Product{}
  |> Product.changeset(%{
    name: "iPhone",
    description: "Apple smartphone with advanced features",
    image: iphone_image,
    organization_id: tech_store.id,
    user_id: admin1.id
  })
  |> Repo.insert!()

# iPhone SKUs
iphone_15_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-15-storage-select-202309-6-1inch-blue?wid=5120&hei=2880&fmt=p-jpg&qlt=80&.v=1692924212810",
    "sku",
    default_sku_image
  )

iphone_15_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "iPhone 15",
    description: "Latest iPhone model with advanced camera system",
    image: iphone_15_image,
    barcode: "1234567890123",
    price: Decimal.new("999.99"),
    cost: Decimal.new("700.00"),
    stock_quantity: 25,
    buffer_level: 5,
    rfid_tag: "RF123456789",
    product_id: iphone.id,
    organization_id: tech_store.id,
    user_id: admin1.id
  })
  |> Repo.insert!()

iphone_15_pro_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-15-pro-max-select-202309-6-7inch-naturaltitanium?wid=5120&hei=2880&fmt=p-jpg&qlt=80&.v=1692845702708",
    "sku",
    default_sku_image
  )

iphone_15_pro_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "iPhone 15 Pro",
    description: "Pro model with titanium design and A17 Pro chip",
    image: iphone_15_pro_image,
    barcode: "1234567890124",
    price: Decimal.new("1199.99"),
    cost: Decimal.new("850.00"),
    stock_quantity: 15,
    buffer_level: 3,
    rfid_tag: "RF123456790",
    product_id: iphone.id,
    organization_id: tech_store.id,
    user_id: admin1.id
  })
  |> Repo.insert!()

# MacBook product
macbook_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/macbook-air-space-gray-select-201810?wid=904&hei=840&fmt=jpeg&qlt=90&.v=1633027804000",
    "product",
    default_product_image
  )

macbook =
  %Product{}
  |> Product.changeset(%{
    name: "MacBook",
    description: "Apple laptop computers for professional and personal use",
    image: macbook_image,
    organization_id: tech_store.id,
    user_id: admin1.id
  })
  |> Repo.insert!()

# MacBook SKUs
macbook_air_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/macbook-air-midnight-select-20220606?wid=904&hei=840&fmt=jpeg&qlt=90&.v=1653084303665",
    "sku",
    default_sku_image
  )

macbook_air_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "MacBook Air",
    description: "Ultra-thin, lightweight laptop with M2 chip",
    image: macbook_air_image,
    barcode: "2234567890123",
    price: Decimal.new("1299.99"),
    cost: Decimal.new("900.00"),
    stock_quantity: 10,
    buffer_level: 2,
    rfid_tag: "RF223456789",
    product_id: macbook.id,
    organization_id: tech_store.id,
    user_id: admin1.id
  })
  |> Repo.insert!()

macbook_pro_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mbp-spacegray-select-202206?wid=904&hei=840&fmt=jpeg&qlt=90&.v=1664497359481",
    "sku",
    default_sku_image
  )

macbook_pro_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "MacBook Pro",
    description: "Powerful laptop for professionals with M2 Pro chip",
    image: macbook_pro_image,
    barcode: "2234567890124",
    price: Decimal.new("1999.99"),
    cost: Decimal.new("1400.00"),
    stock_quantity: 8,
    buffer_level: 2,
    rfid_tag: "RF223456790",
    product_id: macbook.id,
    organization_id: tech_store.id,
    user_id: admin1.id
  })
  |> Repo.insert!()

# ============================================================================
# Create FashionForward Products and SKUs
# ============================================================================

# T-Shirt product
tshirt_image =
  safe_download_image.(
    "https://img.ltwebstatic.com/images3_pi/2022/01/10/16417919756a32607182dd11dedeb77e8324b683e8_thumbnail_900x.webp",
    "product",
    default_product_image
  )

tshirt =
  %Product{}
  |> Product.changeset(%{
    name: "T-Shirts",
    description: "Comfortable cotton t-shirts in various styles",
    image: tshirt_image,
    organization_id: clothing_store.id,
    user_id: admin2.id
  })
  |> Repo.insert!()

# T-Shirt SKUs
casual_tshirt_image =
  safe_download_image.(
    "https://img.ltwebstatic.com/images3_pi/2021/12/07/1638864944b8e9e0a95e0f6827505fec2bbf70451e_thumbnail_900x.webp",
    "sku",
    default_sku_image
  )

casual_tshirt_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "Casual Cotton T-Shirt",
    description: "Everyday comfortable plain cotton t-shirt",
    image: casual_tshirt_image,
    barcode: "4234567890123",
    price: Decimal.new("19.99"),
    cost: Decimal.new("8.00"),
    stock_quantity: 50,
    buffer_level: 10,
    rfid_tag: "RF423456789",
    product_id: tshirt.id,
    organization_id: clothing_store.id,
    user_id: admin2.id
  })
  |> Repo.insert!()

graphic_tshirt_image =
  safe_download_image.(
    "https://img.ltwebstatic.com/images3_pi/2021/11/15/1636963451f940c14b373dd5c181d5d7e78f1311f2_thumbnail_900x.webp",
    "sku",
    default_sku_image
  )

graphic_tshirt_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "Graphic Print T-Shirt",
    description: "Modern design t-shirt with artistic graphic print",
    image: graphic_tshirt_image,
    barcode: "4234567890124",
    price: Decimal.new("24.99"),
    cost: Decimal.new("10.00"),
    stock_quantity: 35,
    buffer_level: 7,
    rfid_tag: "RF423456790",
    product_id: tshirt.id,
    organization_id: clothing_store.id,
    user_id: admin2.id
  })
  |> Repo.insert!()

# ============================================================================
# Create Products for Kim's Electronics
# ============================================================================

# TV product
tv_image =
  safe_download_image.(
    "https://images.samsung.com/is/image/samsung/p6pim/levant/ua50cu7000uxeg/gallery/levant-uhd-4k-tv-cu7000-ua50cu7000uxeg-536648885?$720_576_PNG$",
    "product",
    default_product_image
  )

tv =
  %Product{}
  |> Product.changeset(%{
    name: "Smart TV",
    description: "4K Smart TV with streaming capabilities",
    image: tv_image,
    organization_id: kim_org.id,
    user_id: kim.id
  })
  |> Repo.insert!()

# TV SKUs
tv_43_image =
  safe_download_image.(
    "https://images.samsung.com/is/image/samsung/p6pim/levant/ua43cu7000uxeg/gallery/levant-uhd-4k-tv-cu7000-ua43cu7000uxeg-536648851?$720_576_PNG$",
    "sku",
    default_sku_image
  )

tv_43_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "43-inch Smart TV",
    description: "43-inch 4K UHD Smart TV with HDR",
    image: tv_43_image,
    barcode: "6234567890123",
    price: Decimal.new("399.99"),
    cost: Decimal.new("250.00"),
    stock_quantity: 15,
    buffer_level: 3,
    rfid_tag: "RF623456789",
    product_id: tv.id,
    organization_id: kim_org.id,
    user_id: kim.id
  })
  |> Repo.insert!()

tv_55_image =
  safe_download_image.(
    "https://images.samsung.com/is/image/samsung/p6pim/levant/ua55cu7000uxeg/gallery/levant-uhd-4k-tv-cu7000-ua55cu7000uxeg-536648926?$720_576_PNG$",
    "sku",
    default_sku_image
  )

tv_55_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "55-inch Smart TV",
    description: "55-inch 4K UHD Smart TV with HDR and voice control",
    image: tv_55_image,
    barcode: "6234567890124",
    price: Decimal.new("599.99"),
    cost: Decimal.new("350.00"),
    stock_quantity: 10,
    buffer_level: 2,
    rfid_tag: "RF623456790",
    product_id: tv.id,
    organization_id: kim_org.id,
    user_id: kim.id
  })
  |> Repo.insert!()

# ============================================================================
# Create Products for Mike's Furniture
# ============================================================================

# Sofa product
sofa_image =
  safe_download_image.(
    "https://www.ikea.com/us/en/images/products/kivik-sofa-with-chaise-hillared-beige__0479837_pe618676_s5.jpg",
    "product",
    default_product_image
  )

sofa =
  %Product{}
  |> Product.changeset(%{
    name: "Sofa",
    description: "Comfortable sofas for your living room",
    image: sofa_image,
    organization_id: mike_org.id,
    user_id: mike.id
  })
  |> Repo.insert!()

# Sofa SKUs
sectional_sofa_image =
  safe_download_image.(
    "https://www.ikea.com/us/en/images/products/finnala-sectional-5-seat-corner-with-chaise-gunnared-medium-gray__0818193_pe774293_s5.jpg",
    "sku",
    default_sku_image
  )

sectional_sofa_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "Sectional Sofa",
    description: "L-shaped sectional sofa with chaise lounge",
    image: sectional_sofa_image,
    barcode: "7234567890123",
    price: Decimal.new("899.99"),
    cost: Decimal.new("500.00"),
    stock_quantity: 5,
    buffer_level: 1,
    rfid_tag: "RF723456789",
    product_id: sofa.id,
    organization_id: mike_org.id,
    user_id: mike.id
  })
  |> Repo.insert!()

loveseat_image =
  safe_download_image.(
    "https://www.ikea.com/us/en/images/products/glostad-loveseat-knisa-dark-gray__0950867_pe800736_s5.jpg",
    "sku",
    default_sku_image
  )

loveseat_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "Loveseat",
    description: "Compact 2-seater sofa perfect for smaller spaces",
    image: loveseat_image,
    barcode: "7234567890124",
    price: Decimal.new("349.99"),
    cost: Decimal.new("200.00"),
    stock_quantity: 8,
    buffer_level: 2,
    rfid_tag: "RF723456790",
    product_id: sofa.id,
    organization_id: mike_org.id,
    user_id: mike.id
  })
  |> Repo.insert!()

# ============================================================================
# Create Products for Kevin's Groceries
# ============================================================================

# Fruit product
fruit_image =
  safe_download_image.(
    "https://hips.hearstapps.com/hmg-prod/images/assortment-of-colorful-ripe-tropical-fruits-top-royalty-free-image-995518546-1564092355.jpg",
    "product",
    default_product_image
  )

fruit =
  %Product{}
  |> Product.changeset(%{
    name: "Fresh Fruit",
    description: "Seasonal fresh fruits from local farms",
    image: fruit_image,
    organization_id: kevin_org.id,
    user_id: kevin.id
  })
  |> Repo.insert!()

# Fruit SKUs
apple_image =
  safe_download_image.(
    "https://5.imimg.com/data5/WA/NV/LI/SELLER-52971039/apple-fruit.jpg",
    "sku",
    default_sku_image
  )

apple_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "Organic Apples",
    description: "Organic, locally grown apples (price per pound)",
    image: apple_image,
    barcode: "8234567890123",
    price: Decimal.new("2.99"),
    cost: Decimal.new("1.50"),
    stock_quantity: 100,
    buffer_level: 20,
    rfid_tag: "RF823456789",
    product_id: fruit.id,
    organization_id: kevin_org.id,
    user_id: kevin.id
  })
  |> Repo.insert!()

banana_image =
  safe_download_image.(
    "https://i5.walmartimages.com/asr/5feccc1d-c179-4d9d-a7d6-8d85951afa28.2dd24ee656b7c80d6c45be7f0ae40da0.jpeg",
    "sku",
    default_sku_image
  )

banana_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "Organic Bananas",
    description: "Organic, fair trade bananas (price per bunch)",
    image: banana_image,
    barcode: "8234567890124",
    price: Decimal.new("1.99"),
    cost: Decimal.new("0.89"),
    stock_quantity: 80,
    buffer_level: 15,
    rfid_tag: "RF823456790",
    product_id: fruit.id,
    organization_id: kevin_org.id,
    user_id: kevin.id
  })
  |> Repo.insert!()

# ============================================================================
# Create Products for Kim's Electronics
# ============================================================================
# Laptop product
laptop_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mbp-spacegray-select-202206?wid=904&hei=840&fmt=jpeg&qlt=90&.v=1664497359481",
    "product",
    default_product_image
  )

laptop =
  %Product{}
  |> Product.changeset(%{
    name: "Laptop",
    description: "High-performance laptops for work and play",
    image: laptop_image,
    organization_id: kim_org.id,
    user_id: kim.id
  })
  |> Repo.insert!()

# Laptop SKUs
laptop_air_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mbp-spacegray-select-202206?wid=904&hei=840&fmt=jpeg&qlt=90&.v=1664497359481",
    "sku",
    default_sku_image
  )

laptop_air_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "MacBook Air",
    description: "Lightweight laptop with M1 chip",
    image: laptop_air_image,
    barcode: "9234567890123",
    price: Decimal.new("999.99"),
    cost: Decimal.new("700.00"),
    stock_quantity: 20,
    buffer_level: 5,
    rfid_tag: "RF923456789",
    product_id: laptop.id,
    organization_id: kim_org.id,
    user_id: kim.id
  })
  |> Repo.insert!()

laptop_pro_image =
  safe_download_image.(
    "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mbp-spacegray-select-202206?wid=904&hei=840&fmt=jpeg&qlt=90&.v=1664497359481",
    "sku",
    default_sku_image
  )

laptop_pro_sku =
  %ProductSku{}
  |> ProductSku.changeset(%{
    name: "MacBook Pro",
    description: "Powerful laptop with M1 Pro chip",
    image: laptop_pro_image,
    barcode: "9234567890124",
    price: Decimal.new("1299.99"),
    cost: Decimal.new("900.00"),
    stock_quantity: 12,
    buffer_level: 3,
    rfid_tag: "RF923456790",
    product_id: laptop.id,
    organization_id: kim_org.id,
    user_id: kim.id
  })
  |> Repo.insert!()

# ============================================================================
# Create Sales and Sale Items
# ============================================================================
# Create a sale for Kim's Electronics
sale1 =
  %Sale{}
  |> Sale.changeset(%{
    total: Decimal.new("0.00"),
    payment_method: "credit_card",
    status: "completed",
    organization_id: kim_org.id,
    user_id: kim.id,
    register_id: 1
  })
  |> Repo.insert!()

sale_item1 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "MacBook Air",
    quantity: 1,
    price: Decimal.new("999.99"),
    subtotal: Decimal.new("999.99"),
    product_sku_id: laptop_air_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item2 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Banana",
    quantity: 2,
    price: Decimal.new("1.99"),
    subtotal: Decimal.new("3.98"),
    product_sku_id: banana_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item3 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "55-inch 4K TV",
    quantity: 1,
    price: Decimal.new("399.99"),
    subtotal: Decimal.new("399.99"),
    product_sku_id: tv_55_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item4 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Graphic T-Shirt",
    quantity: 1,
    price: Decimal.new("24.99"),
    subtotal: Decimal.new("24.99"),
    product_sku_id: graphic_tshirt_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item5 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Casual T-Shirt",
    quantity: 1,
    price: Decimal.new("19.99"),
    subtotal: Decimal.new("19.99"),
    product_sku_id: casual_tshirt_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item6 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Apple",
    quantity: 1,
    price: Decimal.new("2.99"),
    subtotal: Decimal.new("2.99"),
    product_sku_id: apple_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item7 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Loveseat",
    quantity: 1,
    price: Decimal.new("349.99"),
    subtotal: Decimal.new("349.99"),
    product_sku_id: loveseat_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item8 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Sectional Sofa",
    quantity: 1,
    price: Decimal.new("899.99"),
    subtotal: Decimal.new("899.99"),
    product_sku_id: sectional_sofa_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item9 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "43-inch Smart TV",
    quantity: 1,
    price: Decimal.new("599.99"),
    subtotal: Decimal.new("599.99"),
    product_sku_id: tv_43_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item10 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "iPhone 15 Pro",
    quantity: 1,
    price: Decimal.new("399.99"),
    subtotal: Decimal.new("399.99"),
    product_sku_id: iphone_15_pro_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item11 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "MacBook Pro",
    quantity: 1,
    price: Decimal.new("1299.99"),
    subtotal: Decimal.new("1299.99"),
    product_sku_id: macbook_pro_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item12 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Casual T-Shirt",
    quantity: 1,
    price: Decimal.new("19.99"),
    subtotal: Decimal.new("19.99"),
    product_sku_id: casual_tshirt_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item13 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Graphic T-Shirt",
    quantity: 1,
    price: Decimal.new("24.99"),
    subtotal: Decimal.new("24.99"),
    product_sku_id: graphic_tshirt_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item14 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Apple",
    quantity: 1,
    price: Decimal.new("2.99"),
    subtotal: Decimal.new("2.99"),
    product_sku_id: apple_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item15 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Banana",
    quantity: 1,
    price: Decimal.new("1.99"),
    subtotal: Decimal.new("1.99"),
    product_sku_id: banana_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

sale_item16 =
  %SaleItem{}
  |> SaleItem.changeset(%{
    name: "Loveseat",
    quantity: 1,
    price: Decimal.new("349.99"),
    subtotal: Decimal.new("349.99"),
    product_sku_id: loveseat_sku.id,
    sale_id: sale1.id,
    organization_id: kim_org.id
  })
  |> Repo.insert!()

# end seed
# Commit the transaction
