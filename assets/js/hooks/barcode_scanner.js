// assets/js/hooks/barcode_scanner.js
import Quagga from '@ericblade/quagga2';

const BarcodeScanner = {
  mounted() {
    this.setupUI();
    this.lastScannedBarcode = null;
    this.lastScanTime = 0;
    this.scanCooldown = 3000; // 3 seconds cooldown between same barcode scans

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
  }
};

export default BarcodeScanner;