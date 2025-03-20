defmodule AiposWeb.Landing do
  use Phoenix.Component

  def landing(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <nav class="bg-slate-900 fixed w-full z-50">
        <div class="container mx-auto max-w-7xl px-6 py-4">
          <div class="flex items-center justify-between">
            <.link navigate="/">
              <div class="flex items-center space-x-2">
                <img src="/images/test2.png" class="h-[40px] w-[150px]" />
              </div>
            </.link>

            <div class="flex items-center space-x-4">
              <%= if @current_user do %>
                <.link
                  navigate="/businesses"
                  class="bg-[#143D8D] text-white px-4 py-2 rounded-lg hover:bg-blue-600 transition-colors duration-200 flex items-center"
                >
                  Dashboard
                </.link>
              <% else %>
                <.link
                  navigate="/users/log_in"
                  class="bg-[#143D8D] text-white px-4 py-2 rounded-lg hover:bg-blue-600 transition-colors duration-200 flex items-center"
                >
                  Sign in
                </.link>
              <% end %>
            </div>
          </div>
        </div>
      </nav>

      <div class="flex-grow bg-slate-900">
        <div class="container mx-auto max-w-7xl px-6 pt-24">
          <div class="min-h-[calc(100vh-6rem)] flex items-center">
            <div class="flex flex-col lg:flex-row items-center justify-between w-full gap-12">
              <div class="lg:w-1/2 space-y-8">
                <h1 class="text-4xl md:text-5xl font-bold text-[#8DC63F] leading-tight">
                  Revolutionize Your Supermarket Checkout Experience
                </h1>
                <p class="text-gray-400 text-lg leading-relaxed">
                  Our AI-powered POS system transforms how customers shop. With in-app self-checkout and WhatsApp ordering capabilities, we're bringing convenience and speed to modern supermarkets. Reduce wait times, increase customer satisfaction, and boost your sales.
                </p>
                <div class="flex flex-col sm:flex-row gap-4">
                  <a
                    href="#"
                    class="bg-[#143D8D] text-white px-6 py-3 rounded-lg hover:bg-blue-600 transition-colors duration-200 text-center flex items-center justify-center"
                  >
                    Request Demo <i class="fas fa-arrow-right ml-2"></i>
                  </a>
                  <a
                    href="#"
                    class="bg-gray-700 text-white px-6 py-3 rounded-lg hover:bg-gray-600 transition-colors duration-200 text-center"
                  >
                    How It Works
                  </a>
                </div>
              </div>

              <div class="lg:w-1/2 h-full">
                <div class="relative">
                  <div class="aspect-video bg-gray-800 rounded-lg overflow-hidden">
                    <img
                      src="/images/ai-pos-showcase.jpg"
                      alt="AI POS System Showcase"
                      class="w-full h-full object-cover"
                    />
                  </div>
                  <div class="absolute -bottom-4 -right-4 bg-white p-4 rounded-lg shadow-lg">
                    <div class="flex items-center space-x-2">
                      <div class="w-10 h-10 rounded-full bg-[#8DC63F] flex items-center justify-center">
                        <i class="fas fa-clock text-white"></i>
                      </div>
                      <div>
                        <p class="text-gray-500 text-xs">Average checkout time</p>
                        <p class="text-gray-900 font-bold">45 seconds</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Features Section -->
      <div class="bg-white py-16">
        <div class="container mx-auto max-w-7xl px-6">
          <h2 class="text-3xl font-bold text-center mb-12">Key Features</h2>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <!-- Feature 1 -->
            <div class="bg-gray-50 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-[#143D8D] rounded-full flex items-center justify-center mr-4">
                  <i class="fas fa-mobile-alt text-white text-lg"></i>
                </div>
                <h3 class="text-xl font-semibold">Self-Checkout App</h3>
              </div>
              <p class="text-gray-600">
                Customers can scan items, pay, and complete checkout directly from their smartphones.
              </p>
            </div>
            
    <!-- Feature 2 -->
            <div class="bg-gray-50 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-[#143D8D] rounded-full flex items-center justify-center mr-4">
                  <i class="fab fa-whatsapp text-white text-lg"></i>
                </div>
                <h3 class="text-xl font-semibold">WhatsApp Orders</h3>
              </div>
              <p class="text-gray-600">
                Customers can place orders directly via WhatsApp for delivery or in-store pickup.
              </p>
            </div>
            
    <!-- Feature 3 -->
            <div class="bg-gray-50 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-[#143D8D] rounded-full flex items-center justify-center mr-4">
                  <i class="fas fa-brain text-white text-lg"></i>
                </div>
                <h3 class="text-xl font-semibold">AI-Powered Analytics</h3>
              </div>
              <p class="text-gray-600">
                Get powerful insights on shopping patterns, inventory management, and customer preferences.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def footer(assigns) do
    ~H"""
    <footer class="bg-gradient-to-br from-gray-900 to-gray-800 text-gray-300 relative z-10 pt-16">
      <div class="container mx-auto max-w-7xl px-6 pb-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12">
          <!-- Brand Section -->
          <div class="lg:col-span-2 space-y-6">
            <div class="space-y-4">
              <h3 class="text-[#8DC63F] font-bold text-xl">SmartCheckout</h3>
              <p class="text-gray-400 lg:w-4/5">
                Our AI-powered POS system brings cutting-edge technology to supermarkets, enabling self-checkout through mobile apps and seamless ordering via WhatsApp. Enhance customer experience, reduce wait times, and boost your sales.
              </p>
            </div>

            <div class="flex items-center space-x-4 pt-4">
              <a href="#" class="text-gray-400 hover:text-[#8DC63F] transition-colors duration-300">
                <i class="fab fa-facebook-f text-lg"></i>
              </a>
              <a href="#" class="text-gray-400 hover:text-[#8DC63F] transition-colors duration-300">
                <i class="fab fa-twitter text-lg"></i>
              </a>
              <a href="#" class="text-gray-400 hover:text-[#8DC63F] transition-colors duration-300">
                <i class="fab fa-instagram text-lg"></i>
              </a>
              <a href="#" class="text-gray-400 hover:text-[#8DC63F] transition-colors duration-300">
                <i class="fab fa-linkedin-in text-lg"></i>
              </a>
            </div>
          </div>
          
    <!-- Quick Links -->
          <div class="space-y-6">
            <h3 class="text-white font-bold text-lg relative inline-block pb-2">
              Quick Links <span class="absolute bottom-0 left-0 w-12 h-0.5 bg-[#8DC63F]"></span>
            </h3>
            <ul class="space-y-3">
              <li>
                <a href="#" class="text-gray-400 hover:text-white transition-colors duration-300">
                  Features
                </a>
              </li>
              <li>
                <a href="#" class="text-gray-400 hover:text-white transition-colors duration-300">
                  Pricing
                </a>
              </li>
              <li>
                <a href="#" class="text-gray-400 hover:text-white transition-colors duration-300">
                  Testimonials
                </a>
              </li>
              <li>
                <a href="#" class="text-gray-400 hover:text-white transition-colors duration-300">
                  FAQs
                </a>
              </li>
            </ul>
          </div>
          
    <!-- Contact Info -->
          <div class="space-y-6">
            <h3 class="text-white font-bold text-lg relative inline-block pb-2">
              Contact Info <span class="absolute bottom-0 left-0 w-12 h-0.5 bg-[#8DC63F]"></span>
            </h3>
            <ul class="space-y-4">
              <li>
                <a
                  href="mailto:info@smartcheckout.com"
                  class="group flex items-center gap-3 hover:text-white transition-all duration-300"
                >
                  <div class="w-8 h-8 bg-gray-800 rounded-full flex items-center justify-center group-hover:bg-[#8DC63F] transition-colors duration-300">
                    <i class="fas fa-envelope text-[#8DC63F] text-sm group-hover:text-white"></i>
                  </div>
                  <span class="text-sm">info@smartcheckout.com</span>
                </a>
              </li>
              <li>
                <a
                  href="tel:+1234567890"
                  class="group flex items-center gap-3 hover:text-white transition-all duration-300"
                >
                  <div class="w-8 h-8 bg-gray-800 rounded-full flex items-center justify-center group-hover:bg-[#8DC63F] transition-colors duration-300">
                    <i class="fas fa-phone text-[#8DC63F] text-sm group-hover:text-white"></i>
                  </div>
                  <span class="text-sm">+1 (234) 567-890</span>
                </a>
              </li>
              <li>
                <a
                  href="#"
                  class="group flex items-center gap-3 hover:text-white transition-all duration-300"
                >
                  <div class="w-8 h-8 bg-gray-800 rounded-full flex items-center justify-center group-hover:bg-[#8DC63F] transition-colors duration-300">
                    <i class="fas fa-globe text-[#8DC63F] text-sm group-hover:text-white"></i>
                  </div>
                  <span class="text-sm">www.smartcheckout.com</span>
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div class="border-t border-gray-700/50 my-8"></div>

        <div class="text-center text-sm text-gray-400">
          <p class="hover:text-white transition-colors duration-300">
            © {DateTime.utc_now().year} SmartCheckout. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
    """
  end
end
