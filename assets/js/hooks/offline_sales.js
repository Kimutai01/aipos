const DB_NAME = 'aipos-offline';
const DB_VERSION = 2;

function openDB() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 2); // bump to version 2
    req.onupgradeneeded = e => {
      const db = e.target.result;
      if (!db.objectStoreNames.contains('pending_sales')) {
        db.createObjectStore('pending_sales', { keyPath: 'local_id', autoIncrement: true });
      }
      if (!db.objectStoreNames.contains('products')) {
        db.createObjectStore('products', { keyPath: 'id' });
      }
    };
    req.onsuccess = e => resolve(e.target.result);
    req.onerror = e => reject(e.target.error);
  });
}

function dbGetAll(db) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction('pending_sales', 'readonly');
    const req = tx.objectStore('pending_sales').getAll();
    req.onsuccess = e => resolve(e.target.result);
    req.onerror = e => reject(e.target.error);
  });
}

function dbAdd(db, record) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction('pending_sales', 'readwrite');
    const req = tx.objectStore('pending_sales').add(record);
    req.onsuccess = e => resolve(e.target.result);
    req.onerror = e => reject(e.target.error);
  });
}

function dbDelete(db, key) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction('pending_sales', 'readwrite');
    const req = tx.objectStore('pending_sales').delete(key);
    req.onsuccess = () => resolve();
    req.onerror = e => reject(e.target.error);
  });
}

function dbPutAll(db, storeName, records) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(storeName, 'readwrite');
    const store = tx.objectStore(storeName);
    records.forEach(r => store.put(r));
    tx.oncomplete = () => resolve();
    tx.onerror = e => reject(e.target.error);
  });
}

function dbGetAllFrom(db, storeName) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(storeName, 'readonly');
    const req = tx.objectStore(storeName).getAll();
    req.onsuccess = e => resolve(e.target.result);
    req.onerror = e => reject(e.target.error);
  });
}

const OfflineSales = {
  async mounted() {
    this.db = await openDB();
    this.cartState = null;

    // Expose save function globally so onclick can call it when LV is disconnected
    window.saveOfflineSale = () => this.saveCurrentSale();

    // Receive current cart state from LiveView whenever it changes
    this.handleEvent('cart_state', state => {
      this.cartState = state;
    });

    // Trigger sync after LiveView reconnects
    this.handleEvent('trigger_sync', async () => {
      await this.syncPendingSales();
    });

    await this.updateBadge();

    // Sync on mount if online
    if (navigator.onLine) await this.syncPendingSales();
    await this.syncProducts();

    this._onOnline = async () => {
      await this.updateBadge();
      // Give LiveView a moment to reconnect, then sync
      setTimeout(() => this.syncPendingSales(), 2000);
      await this.syncProducts();
    };
    window.addEventListener('online', this._onOnline);
  },

  async saveCurrentSale() {
    const state = this.cartState;
    if (!state || !state.cart_items || state.cart_items.length === 0) {
      alert('Cart is empty — nothing to save.');
      return;
    }

    const sale = {
      cart_items: state.cart_items,
      total_amount: state.total_amount,
      register_id: state.register_id,
      organization_id: state.organization_id,
      customer_id: state.customer_id || null,
      // Use exact total as tendered for offline cash sales
      amount_tendered: state.total_amount,
      saved_at: new Date().toISOString()
    };

    try {
      await dbAdd(this.db, sale);
      await this.updateBadge();
      this.showBanner('offline-saved-banner');
    } catch (e) {
      alert('Failed to save offline sale: ' + e.message);
    }
  },

  async updateBadge() {
    const sales = await dbGetAll(this.db);
    const count = sales.length;

    // Update badge via DOM (works even when LV is disconnected)
    const badge = document.getElementById('pending-sales-badge');
    if (badge) {
      badge.textContent = count > 0 ? `${count} pending sync` : '';
      badge.style.display = count > 0 ? 'inline-flex' : 'none';
    }

    // Also notify LiveView when connected
    try { this.pushEvent('pending_sales_count', { count }); } catch (_) {}
  },

  async syncPendingSales() {
    const sales = await dbGetAll(this.db);
    if (sales.length === 0) return;

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    if (!csrfToken) return;

    let synced = 0;
    let failed = 0;

    for (const sale of sales) {
      try {
        const res = await fetch('/sales/sync', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'x-csrf-token': csrfToken },
          body: JSON.stringify({ sale })
        });

        if (res.ok) {
          await dbDelete(this.db, sale.local_id);
          synced++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }

    await this.updateBadge();
    try { this.pushEvent('sync_complete', { synced, failed }); } catch (_) {}
  },

  async syncProducts() {
    if (!navigator.onLine) return;
    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
      const res = await fetch('/api/products/sync', {
        headers: { 'x-csrf-token': csrfToken }
      });
      if (res.ok) {
        const data = await res.json();
        await dbPutAll(this.db, 'products', data.products || []);
        console.log(`[OfflineSales] Cached ${(data.products || []).length} products for offline use`);
      }
    } catch (e) {
      console.warn('[OfflineSales] Product sync failed:', e.message);
    }
  },

  showBanner(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.remove('hidden');
    setTimeout(() => el.classList.add('hidden'), 3500);
  },

  destroyed() {
    window.removeEventListener('online', this._onOnline);
    delete window.saveOfflineSale;
  }
};

export default OfflineSales;
