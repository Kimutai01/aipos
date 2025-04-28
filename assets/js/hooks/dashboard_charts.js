// assets/js/hooks/dashboard_charts.js
import Chart from 'chart.js/auto';

// Default font settings for all charts
Chart.defaults.font.family = '"Sen", sans-serif';
Chart.defaults.font.size = 12;

const DailySalesChart = {
  mounted() {
    console.log("DailySalesChart mounted"); // Debug log
    this.initChart();
  },
  updated() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.initChart();
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },
  initChart() {
    const canvas = this.el.querySelector('canvas');
    if (!canvas) {
      console.error("Canvas element not found");
      return;
    }

    console.log("Initializing daily sales chart");

    // Get sales data from element's data attribute
    let salesData;
    try {
      salesData = JSON.parse(this.el.dataset.sales || '{}');
      console.log("Parsed sales data:", salesData);
    } catch (e) {
      console.error("Error parsing sales data:", e);
      salesData = {};
    }
    
    // Extract dates and values
    const dates = Object.keys(salesData).sort();
    const amounts = dates.map(date => {
      const value = salesData[date].total || 0;
      return typeof value === 'string' ? parseFloat(value) : value;
    });
    const counts = dates.map(date => salesData[date].count || 0);
    
    // Format dates for display
    const formattedDates = dates.map(date => {
      const parts = date.split('-');
      if (parts.length === 3) {
        return `${parts[2]}/${parts[1]}`; // DD/MM format
      }
      return date;
    });
    
    // Create chart
    this.chart = new Chart(canvas.getContext('2d'), {
      type: 'line',
      data: {
        labels: formattedDates,
        datasets: [
          {
            label: 'Sales Amount (KSh)',
            data: amounts,
            borderColor: 'rgba(59, 130, 246, 1)', // blue
            backgroundColor: 'rgba(59, 130, 246, 0.1)',
            borderWidth: 2,
            fill: true,
            tension: 0.4,
            yAxisID: 'y'
          },
          {
            label: 'Transaction Count',
            data: counts,
            borderColor: 'rgba(16, 185, 129, 1)', // green
            backgroundColor: 'rgba(16, 185, 129, 0)',
            borderWidth: 2,
            borderDash: [5, 5],
            tension: 0.4,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false
        },
        scales: {
          x: {
            ticks: {
              maxRotation: 0,
              autoSkip: true,
              maxTicksLimit: 7,
              font: {
                family: '"Sen", sans-serif'
              }
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: {
              display: true,
              text: 'Amount (KSh)',
              font: {
                family: '"Sen", sans-serif',
                weight: 'bold'
              }
            },
            beginAtZero: true,
            ticks: {
              font: {
                family: '"Sen", sans-serif'
              }
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: {
              display: true,
              text: 'Transaction Count',
              font: {
                family: '"Sen", sans-serif',
                weight: 'bold'
              }
            },
            beginAtZero: true,
            grid: {
              drawOnChartArea: false,
              color: 'rgba(0, 0, 0, 0.05)'
            },
            ticks: {
              precision: 0,
              font: {
                family: '"Sen", sans-serif'
              }
            }
          }
        },
        plugins: {
          tooltip: {
            titleFont: {
              family: '"Sen", sans-serif'
            },
            bodyFont: {
              family: '"Sen", sans-serif'
            },
            callbacks: {
              label: function(context) {
                let label = context.dataset.label || '';
                let value = context.raw;
                
                if (label.includes('Amount')) {
                  return `${label}: KSh ${value.toLocaleString()}`;
                } else {
                  return `${label}: ${value}`;
                }
              }
            }
          },
          legend: {
            position: 'top',
            labels: {
              font: {
                family: '"Sen", sans-serif',
                size: 12
              }
            }
          }
        }
      }
    });
  }
};

const ProductsChart = {
  mounted() {
    console.log("ProductsChart mounted"); // Debug log
    this.initChart();
  },
  updated() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.initChart();
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },
  initChart() {
    const canvas = this.el.querySelector('canvas');
    if (!canvas) {
      console.error("Canvas element not found");
      return;
    }

    console.log("Initializing products chart");

    // Get products data from element's data attribute
    let productsData;
    try {
      productsData = JSON.parse(this.el.dataset.products || '[]');
      console.log("Parsed products data:", productsData);
    } catch (e) {
      console.error('Error parsing products data:', e);
      productsData = [];
    }

    // Extract product names and sales data
    const productNames = productsData.map(p => p.name);
    const productSales = productsData.map(p => typeof p.sold === 'number' ? p.sold : 0);
    
    // Parse revenue values
    const productRevenues = productsData.map(p => {
      if (!p.revenue) return 0;
      
      // Handle both number and string formats
      if (typeof p.revenue === 'number') return p.revenue;
      
      // Parse string with commas
      return parseInt(p.revenue.replace(/,/g, '')) || 0;
    });
    
    // Create color array for the bars
    const backgroundColors = [
      'rgba(59, 130, 246, 0.7)', // blue
      'rgba(16, 185, 129, 0.7)', // green
      'rgba(139, 92, 246, 0.7)', // purple
      'rgba(249, 115, 22, 0.7)', // orange
      'rgba(236, 72, 153, 0.7)'  // pink
    ];
    
    // Create chart
    this.chart = new Chart(canvas.getContext('2d'), {
      type: 'bar',
      data: {
        labels: productNames,
        datasets: [
          {
            label: 'Quantity Sold',
            data: productSales,
            backgroundColor: backgroundColors,
            borderColor: backgroundColors.map(color => color.replace('0.7', '1')),
            borderWidth: 1
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            ticks: {
              font: {
                family: '"Sen", sans-serif'
              }
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
              font: {
                family: '"Sen", sans-serif'
              }
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          }
        },
        plugins: {
          tooltip: {
            titleFont: {
              family: '"Sen", sans-serif'
            },
            bodyFont: {
              family: '"Sen", sans-serif'
            },
            callbacks: {
              label: function(context) {
                const index = context.dataIndex;
                const value = context.raw;
                const revenue = productRevenues[index];
                return `Quantity: ${value} (KSh ${revenue.toLocaleString()})`;
              }
            }
          },
          legend: {
            display: false
          }
        }
      }
    });
  }
};

// Export the hooks
export { DailySalesChart, ProductsChart };