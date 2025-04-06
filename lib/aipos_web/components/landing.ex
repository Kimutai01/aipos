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
                <h2 class="text-2xl font-bold text-white">
                  Smart POS
                </h2>
              </div>
            </.link>

            <div class="flex items-center space-x-4">
              <%= if @current_user do %>
                <.link
                  navigate="/businesses"
                  class="b text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors duration-200 flex items-center bg-purple-600"
                >
                  Dashboard
                </.link>
              <% else %>
                <.link
                  navigate="/users/log_in"
                  class=" text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors duration-200 flex items-center bg-purple-600"
                >
                  Sign in
                </.link>
              <% end %>
            </div>
          </div>
        </div>
      </nav>

      <div class="flex-grow bg-gradient-to-b from-indigo-900 via-[#1a1f36] to-[#111827] relative overflow-hidden">
        <!-- Background decoration elements -->
        <div class="absolute top-0 left-0 w-full h-full overflow-hidden z-0">
          <div class="absolute top-[20%] left-[10%] w-[300px] h-[300px] rounded-full bg-blue-600/10 blur-3xl">
          </div>
          <div class="absolute bottom-[10%] right-[5%] w-[400px] h-[400px] rounded-full bg-[#8DC63F]/10 blur-3xl">
          </div>
          <div class="absolute top-[40%] right-[15%] w-[250px] h-[250px] rounded-full bg-purple-600/10 blur-3xl">
          </div>
        </div>

        <div class="container mx-auto max-w-7xl px-6 pt-24 relative z-10">
          <div class="min-h-[calc(100vh-6rem)] flex items-center">
            <div class="flex flex-col lg:flex-row items-center justify-between w-full gap-12">
              <div class="lg:w-1/2 space-y-8">
                <h1 class="text-4xl md:text-5xl font-bold text-purple-400 leading-tight">
                  Smart Retail Technology for Modern Stores
                </h1>
                <p class="text-gray-200 text-lg leading-relaxed">
                  Our AI-powered POS system transforms retail management with self-shopping capabilities, advanced inventory tracking, and intelligent analytics. Provide customers with product nutritional information, calorie counts, and health benefits while gaining valuable business insights.
                </p>
                <div class="flex flex-col sm:flex-row gap-4">
                  <a
                    href="#"
                    class="bg-purple-600 text-white px-6 py-3 rounded-lg hover:bg-purple-700 transition-colors duration-200 text-center flex items-center justify-center"
                  >
                    Request Demo <i class="fas fa-arrow-right ml-2"></i>
                  </a>
                  <a
                    href="#features"
                    class="bg-white/10 backdrop-blur-sm text-white border border-white/20 px-6 py-3 rounded-lg hover:bg-white/20 transition-colors duration-200 text-center"
                  >
                    Explore Features
                  </a>
                </div>
              </div>

              <div class="lg:w-1/2 h-full">
                <div class="relative">
                  <div class="aspect-video bg-gray-800 rounded-lg overflow-hidden shadow-xl border border-white/10">
                    <img
                      src="/images/dashboard.png"
                      alt="AI POS System Showcase"
                      class="w-full h-full object-cover"
                    />
                    <div class="absolute inset-0 bg-gradient-to-tr from-indigo-900/40 to-transparent">
                    </div>
                  </div>
                  <div class="absolute -bottom-4 -right-4 bg-white backdrop-blur-sm p-4 rounded-lg shadow-lg border border-[#8DC63F]/20">
                    <div class="flex items-center space-x-2">
                      <div class="w-10 h-10 rounded-full bg-purple-600 flex items-center justify-center">
                        <i class="fas fa-chart-line text-white"></i>
                      </div>
                      <div>
                        <p class="text-gray-500 text-xs">Avg. Revenue Increase</p>
                        <p class="text-gray-900 font-bold">24% monthly</p>
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
      <div id="features" class="bg-white py-16">
        <div class="container mx-auto max-w-7xl px-6">
          <h2 class="text-3xl font-bold text-center mb-4">Powerful Features</h2>
          <p class="text-gray-600 text-center mb-12 max-w-3xl mx-auto">
            Our comprehensive POS solution includes everything you need to modernize your retail business and enhance customer experience.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <!-- Feature 1 -->
            <div class="bg-gray-50 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-purple-600 rounded-full flex items-center justify-center mr-4">
                  <i class="fas fa-mobile-alt text-white text-lg"></i>
                </div>
                <h3 class="text-xl font-semibold">Self-Shopping Experience</h3>
              </div>
              <p class="text-gray-600">
                Empower customers to scan products, view nutritional information, and complete checkout directly from their smartphones.
              </p>
            </div>
            
    <!-- Feature 2 -->
            <div class="bg-gray-50 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-purple-600 rounded-full flex items-center justify-center mr-4">
                  <i class="fas fa-brain text-white text-lg"></i>
                </div>
                <h3 class="text-xl font-semibold">AI Business Analytics</h3>
              </div>
              <p class="text-gray-600">
                Get actionable insights on sales trends, inventory management, and supplier performance to optimize your retail operations.
              </p>
            </div>
            
    <!-- Feature 3 -->
            <div class="bg-gray-50 p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300">
              <div class="flex items-center mb-4">
                <div class="w-12 h-12 bg-purple-600 rounded-full flex items-center justify-center mr-4">
                  <i class="fas fa-heartbeat text-white text-lg"></i>
                </div>
                <h3 class="text-xl font-semibold">Nutritional Analysis</h3>
              </div>
              <p class="text-gray-600">
                Provide customers with detailed nutritional information, calorie counts, and health benefits for every product in your store.
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Benefits Section -->
      <div class="bg-gray-100 py-16">
        <div class="container mx-auto max-w-7xl px-6">
          <h2 class="text-3xl font-bold text-center mb-16">Benefits for Your Business</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-16">
            <div class="bg-white p-8 rounded-lg shadow-lg">
              <h3 class="text-2xl font-semibold mb-6 text-purple-500">For Store Owners</h3>
              <ul class="space-y-4">
                <li class="flex items-start">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-purple-600 flex items-center justify-center mr-3 mt-1">
                    <i class="fas fa-check text-white text-xs"></i>
                  </div>
                  <p class="text-gray-700">
                    <span class="font-medium">Increased Revenue:</span>
                    Boost sales with faster checkout and enhanced customer experience
                  </p>
                </li>
                <li class="flex items-start">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-[#8DC63F] flex items-center justify-center mr-3 mt-1">
                    <i class="fas fa-check text-white text-xs"></i>
                  </div>
                  <p class="text-gray-700">
                    <span class="font-medium">Real-time Insights:</span>
                    Track sales, inventory, and supplier performance with powerful dashboards
                  </p>
                </li>
                <li class="flex items-start">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-[#8DC63F] flex items-center justify-center mr-3 mt-1">
                    <i class="fas fa-check text-white text-xs"></i>
                  </div>
                  <p class="text-gray-700">
                    <span class="font-medium">Supplier Management:</span>
                    Optimize ordering and reduce stockouts with intelligent predictions
                  </p>
                </li>
                <li class="flex items-start">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-[#8DC63F] flex items-center justify-center mr-3 mt-1">
                    <i class="fas fa-check text-white text-xs"></i>
                  </div>
                  <p class="text-gray-700">
                    <span class="font-medium">Staff Efficiency:</span>
                    Reduce manual tasks and enable your team to focus on customer service
                  </p>
                </li>
              </ul>
            </div>

            <div class="bg-white p-8 rounded-lg shadow-lg">
              <h3 class="text-2xl font-semibold mb-6 text-purple-500">For Shoppers</h3>
              <ul class="space-y-4">
                <li class="flex items-start">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-[#8DC63F] flex items-center justify-center mr-3 mt-1">
                    <i class="fas fa-check text-white text-xs"></i>
                  </div>
                  <p class="text-gray-700">
                    <span class="font-medium">Nutritional Awareness:</span>
                    Access detailed nutritional information and health benefits for all products
                  </p>
                </li>
                <li class="flex items-start">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-[#8DC63F] flex items-center justify-center mr-3 mt-1">
                    <i class="fas fa-check text-white text-xs"></i>
                  </div>
                  <p class="text-gray-700">
                    <span class="font-medium">Faster Shopping:</span>
                    Skip checkout lines with self-shopping and mobile payment options
                  </p>
                </li>
                <li class="flex items-start">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-[#8DC63F] flex items-center justify-center mr-3 mt-1">
                    <i class="fas fa-check text-white text-xs"></i>
                  </div>
                  <p class="text-gray-700">
                    <span class="font-medium">Personalized Recommendations:</span>
                    Receive tailored product suggestions based on preferences
                  </p>
                </li>
                <li class="flex items-start">
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-[#8DC63F] flex items-center justify-center mr-3 mt-1">
                    <i class="fas fa-check text-white text-xs"></i>
                  </div>
                  <p class="text-gray-700">
                    <span class="font-medium">Shopping History:</span>
                    Track purchases and monitor nutritional patterns over time
                  </p>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
      
    <!-- CTA Section -->
      <div class="bg-indigo-900 py-16">
        <div class="container mx-auto max-w-7xl px-6 text-center">
          <h2 class="text-3xl font-bold text-white mb-6">Ready to Transform Your Store?</h2>
          <p class="text-blue-100 max-w-3xl mx-auto mb-8">
            Join the growing number of retailers using our advanced POS system to increase revenue, improve customer satisfaction, and gain valuable business insights.
          </p>
          <div class="flex flex-col sm:flex-row gap-4 justify-center">
            <a
              href="#"
              class="bg-white text-blue-600 px-8 py-3 rounded-lg hover:bg-gray-100 transition-colors duration-200 font-medium"
            >
              Schedule a Demo
            </a>
            <a
              href="#"
              class="bg-transparent border-2 border-white text-white px-8 py-3 rounded-lg hover:bg-white/10 transition-colors duration-200"
            >
              View Pricing
            </a>
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
              <h3 class="text-purple-400 font-bold text-xl">Smart POS</h3>
              <p class="text-gray-400 lg:w-4/5">
                Our AI-powered POS system brings cutting-edge technology to retail, enabling self-shopping with nutritional insights and comprehensive business analytics. Transform customer experience while optimizing your operations.
              </p>
            </div>

            <div class="flex items-center space-x-4 pt-4">
              <a href="#" class="text-gray-400 hover:text-purple-500 transition-colors duration-300">
                <i class="fab fa-facebook-f text-lg"></i>
              </a>
              <a href="#" class="text-gray-400 hover:text-purple-500 transition-colors duration-300">
                <i class="fab fa-twitter text-lg"></i>
              </a>
              <a href="#" class="text-gray-400 hover:text-purple-500 transition-colors duration-300">
                <i class="fab fa-instagram text-lg"></i>
              </a>
              <a href="#" class="text-gray-400 hover:text-purple-500 transition-colors duration-300">
                <i class="fab fa-linkedin-in text-lg"></i>
              </a>
            </div>
          </div>
          
    <!-- Quick Links -->
          <div class="space-y-6">
            <h3 class="text-white font-bold text-lg relative inline-block pb-2">
              Quick Links <span class="absolute bottom-0 left-0 w-12 h-0.5 bg-purple-500"></span>
            </h3>
            <ul class="space-y-3">
              <li>
                <a
                  href="#features"
                  class="text-gray-400 hover:text-white transition-colors duration-300"
                >
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
                  Case Studies
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
              Contact Info <span class="absolute bottom-0 left-0 w-12 h-0.5 bg-purple-500"></span>
            </h3>
            <ul class="space-y-4">
              <li>
                <a
                  href="mailto:info@smartpos.com"
                  class="group flex items-center gap-3 hover:text-white transition-all duration-300"
                >
                  <div class="w-8 h-8 bg-gray-800 rounded-full flex items-center justify-center group-hover:bg-purple-600 transition-colors duration-300">
                    <i class="fas fa-envelope text-purple-500 text-sm group-hover:text-white"></i>
                  </div>
                  <span class="text-sm">info@smartpos.com</span>
                </a>
              </li>
              <li>
                <a
                  href="tel:+1234567890"
                  class="group flex items-center gap-3 hover:text-white transition-all duration-300"
                >
                  <div class="w-8 h-8 bg-gray-800 rounded-full flex items-center justify-center group-hover:bg-purple-600 transition-colors duration-300">
                    <i class="fas fa-phone text-purple-500 text-sm group-hover:text-white"></i>
                  </div>
                  <span class="text-sm">+1 (234) 567-890</span>
                </a>
              </li>
              <li>
                <a
                  href="#"
                  class="group flex items-center gap-3 hover:text-white transition-all duration-300"
                >
                  <div class="w-8 h-8 bg-gray-800 rounded-full flex items-center justify-center group-hover:bg-purple-600 transition-colors duration-300">
                    <i class="fas fa-globe text-purple-500 text-sm group-hover:text-white"></i>
                  </div>
                  <span class="text-sm">www.smartpos.com</span>
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div class="border-t border-gray-700/50 my-8"></div>

        <div class="text-center text-sm text-gray-400">
          <p class="hover:text-white transition-colors duration-300">
            © {DateTime.utc_now().year} Smart POS. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
    """
  end
end
