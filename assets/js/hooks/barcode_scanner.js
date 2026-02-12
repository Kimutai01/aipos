// assets/js/hooks/barcode_scanner.js
import Quagga from '@ericblade/quagga2';

const BarcodeScanner = {
  mounted() {
    this.setupUI();
    this.lastScannedBarcode = null;
    this.lastScanTime = 0;
    this.scanCooldown = 3000; // 3 seconds cooldown between same barcode scans

    // Make print function globally accessible for direct calls
    window.printReceipt = () => {
      console.log('Window.printReceipt called');
      this.printReceipt();
    };

    // Make close receipt function globally accessible
    window.closeReceipt = () => {
      console.log('Window.closeReceipt called - sending event to LiveView');
      this.pushEvent("close_receipt", {});
    };

    // Close scanner when escape key is pressed
    window.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.isScanning) {
        this.stopScanner();
      }
    });
    
    // Listen for AI modal events from server
    this.handleEvent("scan_success", () => {
      // Server confirmed scan was successful, stop scanner
      this.stopScanner();
    });

    // Listen for print receipt event
    this.handleEvent("print_receipt", () => {
      console.log('Print receipt event received from LiveView');
      this.printReceipt();
    });

    // Listen for cash drawer opening event
    this.handleEvent("open_cash_drawer", () => {
      this.openCashDrawer();
    });
  },

  setupUI() {
    // Create scanner button
    const scannerButton = document.createElement('button');
    scannerButton.className = 'fixed bottom-4 right-4 bg-blue-600 text-white p-3 rounded-full shadow-lg z-30';
    scannerButton.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M3 14h18m-9-4v8m-7 0h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>';
    scannerButton.title = 'Scan Product Barcode';
    scannerButton.addEventListener('click', () => this.toggleScanner());
    document.body.appendChild(scannerButton);
    this.scannerButton = scannerButton;

    // Create scanner overlay (hidden initially)
    const scannerOverlay = document.createElement('div');
    scannerOverlay.className = 'fixed inset-0 bg-black bg-opacity-75 z-40 flex flex-col items-center justify-center hidden';
    
    // Create scanner viewport
    const viewport = document.createElement('div');
    viewport.className = 'relative w-full max-w-lg aspect-[4/3] bg-black';
    viewport.id = 'barcode-scanner-viewport';
    
    // Create close button
    const closeButton = document.createElement('button');
    closeButton.className = 'absolute top-2 right-2 bg-white p-2 rounded-full z-10';
    closeButton.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>';
    closeButton.addEventListener('click', () => this.stopScanner());
    viewport.appendChild(closeButton);
    
    // Create canvas for Quagga
    const canvas = document.createElement('div');
    canvas.id = 'barcode-scanner-canvas';
    canvas.className = 'w-full h-full';
    viewport.appendChild(canvas);
    
    // Create status text
    const statusText = document.createElement('div');
    statusText.className = 'text-white text-center mt-4 text-lg font-medium';
    statusText.textContent = 'Point camera at product barcode';
    
    // Add components to overlay
    scannerOverlay.appendChild(viewport);
    scannerOverlay.appendChild(statusText);
    document.body.appendChild(scannerOverlay);
    
    this.scannerOverlay = scannerOverlay;
    this.statusText = statusText;
    this.isScanning = false;
  },

  toggleScanner() {
    if (this.isScanning) {
      this.stopScanner();
    } else {
      this.startScanner();
    }
  },

  startScanner() {
    this.scannerOverlay.classList.remove('hidden');
    this.isScanning = true;
    this.statusText.textContent = 'Initializing camera...';
    
    // Reset tracking for new scan session
    this.lastScannedBarcode = null;
    this.lastScanTime = 0;
    
    // Initialize Quagga
    Quagga.init({
      inputStream: {
        name: "Live",
        type: "LiveStream",
        target: document.getElementById('barcode-scanner-canvas'),
        constraints: {
          facingMode: "environment", // use the rear camera
          width: { min: 640 },
          height: { min: 480 },
          aspectRatio: { min: 1, max: 2 }
        }
      },
      locator: {
        patchSize: "medium",
        halfSample: true
      },
      numOfWorkers: 2,
      frequency: 10,
      decoder: {
        readers: [
          "ean_reader",
          "ean_8_reader",
          "code_128_reader",
          "code_39_reader",
          "upc_reader",
          "upc_e_reader"
        ]
      },
      locate: true
    }, (err) => {
      if (err) {
        console.error("Error initializing barcode scanner:", err);
        this.statusText.textContent = "Camera access error. Please allow camera access.";
        return;
      }
      
      // Start Quagga
      Quagga.start();
      
      // Update status once camera is ready
      this.statusText.textContent = 'Point camera at product barcode';
      
      // Handle detected barcodes
      Quagga.onDetected(this.handleBarcodeDetection.bind(this));
    });
  },

  stopScanner() {
    if (this.isScanning) {
      Quagga.stop();
      this.scannerOverlay.classList.add('hidden');
      this.isScanning = false;
    }
  },

  handleBarcodeDetection(result) {
    // Get barcode
    const barcode = result.codeResult.code;
    const currentTime = new Date().getTime();
    
    // Check if this is a duplicate scan (same barcode within cooldown period)
    if (barcode === this.lastScannedBarcode && 
        (currentTime - this.lastScanTime) < this.scanCooldown) {
      // Update status but don't process as a new scan
      this.statusText.textContent = `Already scanned: ${barcode}`;
      return;
    }
    
    // Update last scan tracking
    this.lastScannedBarcode = barcode;
    this.lastScanTime = currentTime;
    
    // Vibrate if available
    if (navigator.vibrate) {
      navigator.vibrate(100);
    }
    
    // Show the detected barcode
    this.statusText.textContent = `Detected: ${barcode}`;
    
    // Push barcode to the server
    this.pushEvent("barcode_scanned", { barcode });
    
    // We'll now let the server respond with a "scan_success" event to close the scanner
    // This way we keep it open if product not found or other error
    this.statusText.textContent = `Processing: ${barcode}...`;
    
    // Add a timeout for safety
    setTimeout(() => {
      if (this.isScanning) {
        this.stopScanner();
      }
    }, 5000);
  },

  printReceipt() {
    console.log('Print receipt triggered');
    // Print the receipt content
    const receiptContent = document.getElementById('receipt-content');
    if (!receiptContent) {
      console.error('Receipt content not found');
      alert('Receipt content not found. Please try again.');
      return;
    }
    console.log('Receipt content found, opening print window...');

    // Create a new window for printing
    const printWindow = window.open('', '_blank', 'width=800,height=600');
    if (!printWindow) {
      console.error('Could not open print window. Please check popup blocker.');
      alert('Please allow popups to print receipts. Check your browser popup blocker settings.');
      return;
    }
    console.log('Print window opened successfully');

    // Write the receipt content with styles
    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Print Receipt</title>
          <style>
            @media print {
              @page {
                size: 80mm auto;
                margin: 5mm;
              }
              body {
                margin: 0;
                padding: 0;
              }
            }
            body {
              font-family: 'Courier New', monospace;
              font-size: 12px;
              line-height: 1.4;
              max-width: 80mm;
              margin: 0 auto;
              padding: 5mm;
            }
            h3 {
              font-size: 16px;
              margin: 0 0 5px 0;
              font-weight: bold;
            }
            table {
              width: 100%;
              border-collapse: collapse;
              margin: 10px 0;
            }
            th, td {
              padding: 4px 2px;
              text-align: left;
            }
            th {
              border-bottom: 1px solid #000;
              font-weight: bold;
            }
            tr {
              border-bottom: 1px dashed #ccc;
            }
            .text-center {
              text-align: center;
            }
            .text-right {
              text-align: right;
            }
            .font-bold {
              font-weight: bold;
            }
            .border-t {
              border-top: 1px solid #000;
              padding-top: 8px;
            }
            .space-y-2 > * + * {
              margin-top: 8px;
            }
            img {
              max-width: 40mm !important;
              max-height: 40mm !important;
              width: auto !important;
              height: auto !important;
              object-fit: contain !important;
            }
          </style>
        </head>
        <body>
          ${receiptContent.innerHTML}
        </body>
      </html>
    `);

    printWindow.document.close();
    
    // Wait for content to load, then print
    printWindow.onload = function() {
      printWindow.focus();
      printWindow.print();
      
      // Close the window after printing or canceling
      setTimeout(() => {
        printWindow.close();
      }, 100);
    };
  },

  openCashDrawer() {
    /**
     * Cash Drawer Opening Mechanism
     * 
     * Most modern POS cash drawers are connected to receipt printers via an RJ11/RJ12 cable.
     * The printer sends an ESC/POS command to trigger the drawer to open.
     * 
     * There are several methods to open a cash drawer:
     * 
     * 1. Via Receipt Printer (Most Common):
     *    - Send ESC/POS command: ESC p m t1 t2 (hex: 1B 70 00 19 FA)
     *    - This is the most reliable method for web-based POS systems
     * 
     * 2. Via Serial/USB (Desktop Apps):
     *    - Direct serial communication (requires native app or Electron)
     *    - Not available in web browsers due to security restrictions
     * 
     * 3. Via Network (Cloud-based):
     *    - Some modern drawers support network protocols
     *    - Requires local server/daemon running on the POS machine
     * 
     * For this web-based implementation, we'll use the Web Serial API (Chrome 89+)
     * as a fallback, but the primary method should be through the receipt printer.
     */

    console.log('Opening cash drawer...');

    // Method 1: Try to open via Web Serial API (if supported and connected)
    if ('serial' in navigator) {
      this.openCashDrawerViaSerial();
    } else {
      console.warn('Web Serial API not supported. Cash drawer must be opened via receipt printer.');
      
      // Show a notification that the drawer should open
      this.showCashDrawerNotification();
    }

    // Method 2: If you have a local printing service/daemon, you can call it here
    // Example: fetch('http://localhost:9100/cash-drawer/open', { method: 'POST' });
  },

  async openCashDrawerViaSerial() {
    try {
      // Check if we have a stored port
      const ports = await navigator.serial.getPorts();
      let port = ports.length > 0 ? ports[0] : null;

      if (!port) {
        console.log('No serial port found. User may need to connect cash drawer.');
        this.showCashDrawerNotification();
        return;
      }

      // Open the port
      if (!port.readable) {
        await port.open({ baudRate: 9600 });
      }

      // ESC/POS command to open cash drawer: ESC p m t1 t2
      // ESC = 27 (0x1B), p = 112 (0x70)
      // m = pin number (0 for pin 2, 1 for pin 5)
      // t1 = ON time (in milliseconds * 2)
      // t2 = OFF time (in milliseconds * 2)
      const command = new Uint8Array([0x1B, 0x70, 0x00, 0x19, 0xFA]);

      const writer = port.writable.getWriter();
      await writer.write(command);
      writer.releaseLock();

      console.log('Cash drawer open command sent successfully');
      
    } catch (error) {
      console.error('Error opening cash drawer via serial:', error);
      this.showCashDrawerNotification();
    }
  },

  showCashDrawerNotification() {
    // Visual feedback that cash drawer should open
    const notification = document.createElement('div');
    notification.className = 'fixed bottom-4 left-1/2 transform -translate-x-1/2 bg-yellow-500 text-white px-6 py-3 rounded-lg shadow-lg z-50 flex items-center space-x-2';
    notification.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7" />
      </svg>
      <span>Cash Drawer Opening...</span>
    `;
    document.body.appendChild(notification);

    // Beep sound effect
    try {
      const audioContext = new (window.AudioContext || window.webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      oscillator.frequency.value = 800;
      oscillator.type = 'sine';
      gainNode.gain.value = 0.3;
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.1);
    } catch (e) {
      console.error('Could not play beep:', e);
    }

    // Remove notification after 3 seconds
    setTimeout(() => {
      notification.remove();
    }, 3000);
  }
};

export default BarcodeScanner;