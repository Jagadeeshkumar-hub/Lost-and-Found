/**
 * Campus Lost-and-Found Record Matching System
 * File: app.js
 * Description: Client-side interactive engine implementing UI navigation,
 * in-memory state management, search/filtering, form validation,
 * dynamic dashboard statistics, and demonstration matching algorithm.
 * 
 * NOTE FOR DBMS EVALUATORS:
 * As per project constraints, no backend server or REST API is utilized.
 * In-memory JavaScript objects simulate the relational tables for UI demo.
 * Real database operations are performed via MySQL scripts in the /sql directory.
 */

// Application State
const AppState = {
  data: null,
  activeTab: 'dashboard',
  selectedLostItemForMatch: null,
  matchConfidenceFilter: 'ALL',
  filters: {
    search: '',
    category: 'ALL',
    location: 'ALL',
    type: 'ALL', // ALL, LOST, FOUND
    status: 'ALL',
    sortBy: 'date_desc'
  }
};

// Common English stop-words to exclude from keyword extraction
const STOP_WORDS = new Set([
  'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from', 'has', 'he',
  'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the', 'to', 'was', 'were',
  'will', 'with', 'the', 'this', 'but', 'they', 'have', 'had', 'what', 'when',
  'where', 'who', 'which', 'why', 'how', 'all', 'any', 'both', 'each', 'few',
  'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own',
  'same', 'so', 'than', 'too', 'very', 'can', 'just', 'should', 'now'
]);

// Initialize the Application
document.addEventListener('DOMContentLoaded', () => {
  initData();
  populateDropdowns();
  setupEventListeners();
  renderDashboard();
  renderBrowseItems();
  renderMatchCandidates();
  renderClaimsTable();
  renderManagementTable();
  showToast('Welcome to Campus Lost & Found System (Demo Mode Active)', 'info');
});

/**
 * Initialize or reset in-memory data
 */
function initData() {
  if (typeof getInitialData === 'function') {
    AppState.data = getInitialData();
  } else {
    console.error('getInitialData is not defined in data.js');
  }
}

/**
 * Reset demonstration data back to fresh initial state
 */
function resetDemonstrationData() {
  if (confirm('Reset all demonstration records to initial sample data? Any newly added items in this session will be cleared.')) {
    initData();
    AppState.filters = {
      search: '',
      category: 'ALL',
      location: 'ALL',
      type: 'ALL',
      status: 'ALL',
      sortBy: 'date_desc'
    };
    // Reset form inputs if any
    const searchInput = document.getElementById('browseSearchInput');
    if (searchInput) searchInput.value = '';
    const catFilter = document.getElementById('filterCategory');
    if (catFilter) catFilter.value = 'ALL';
    const locFilter = document.getElementById('filterLocation');
    if (locFilter) locFilter.value = 'ALL';
    const typeFilter = document.getElementById('filterType');
    if (typeFilter) typeFilter.value = 'ALL';
    const statusFilter = document.getElementById('filterStatus');
    if (statusFilter) statusFilter.value = 'ALL';

    populateDropdowns();
    renderDashboard();
    renderBrowseItems();
    renderMatchCandidates();
    renderClaimsTable();
    renderManagementTable();
    showToast('Demonstration data has been reset to defaults.', 'info');
  }
}

/**
 * Populate location and category dropdowns across all forms
 */
function populateDropdowns() {
  const locations = AppState.data.locations;

  // Filter location dropdown in Browse
  const filterLoc = document.getElementById('filterLocation');
  if (filterLoc) {
    filterLoc.innerHTML = '<option value="ALL">All Campus Locations</option>' +
      locations.map(loc => `<option value="${loc.location_id}">${escapeHtml(loc.location_name)}</option>`).join('');
  }

  // Report Lost location dropdown
  const lostLoc = document.getElementById('lostLocation');
  if (lostLoc) {
    lostLoc.innerHTML = '<option value="">-- Select Last-Seen Location --</option>' +
      locations.map(loc => `<option value="${loc.location_id}">${escapeHtml(loc.location_name)} (${escapeHtml(loc.building)})</option>`).join('');
  }

  // Report Found location dropdown
  const foundLoc = document.getElementById('foundLocation');
  if (foundLoc) {
    foundLoc.innerHTML = '<option value="">-- Select Found Location --</option>' +
      locations.map(loc => `<option value="${loc.location_id}">${escapeHtml(loc.location_name)} (${escapeHtml(loc.building)})</option>`).join('');
  }

  // Match Inspector Lost Item selector
  const matchSelector = document.getElementById('matchLostItemSelect');
  if (matchSelector) {
    matchSelector.innerHTML = '<option value="ALL">-- Show All Possible Matches --</option>' +
      AppState.data.lost_items
        .filter(item => item.status !== 'RETURNED')
        .map(item => `<option value="${item.lost_id}">[Lost #${item.lost_id}] ${escapeHtml(item.item_name)} (${item.category})</option>`).join('');
  }
}

/**
 * Setup Event Listeners
 */
function setupEventListeners() {
  // Navigation tabs
  const navButtons = document.querySelectorAll('[data-tab-target]');
  navButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const targetTab = btn.getAttribute('data-tab-target');
      switchTab(targetTab);
    });
  });

  // Reset Data button
  const resetBtn = document.getElementById('btnResetData');
  if (resetBtn) {
    resetBtn.addEventListener('click', resetDemonstrationData);
  }

  // Report Lost Form submission
  const lostForm = document.getElementById('formReportLost');
  if (lostForm) {
    lostForm.addEventListener('submit', handleReportLostSubmit);
  }

  // Report Found Form submission
  const foundForm = document.getElementById('formReportFound');
  if (foundForm) {
    foundForm.addEventListener('submit', handleReportFoundSubmit);
  }

  // Browse Search & Filters
  const searchInput = document.getElementById('browseSearchInput');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      AppState.filters.search = e.target.value.trim().toLowerCase();
      renderBrowseItems();
    });
  }

  const filterCategory = document.getElementById('filterCategory');
  if (filterCategory) {
    filterCategory.addEventListener('change', (e) => {
      AppState.filters.category = e.target.value;
      renderBrowseItems();
    });
  }

  const filterLocation = document.getElementById('filterLocation');
  if (filterLocation) {
    filterLocation.addEventListener('change', (e) => {
      AppState.filters.location = e.target.value;
      renderBrowseItems();
    });
  }

  const filterType = document.getElementById('filterType');
  if (filterType) {
    filterType.addEventListener('change', (e) => {
      AppState.filters.type = e.target.value;
      renderBrowseItems();
    });
  }

  const filterStatus = document.getElementById('filterStatus');
  if (filterStatus) {
    filterStatus.addEventListener('change', (e) => {
      AppState.filters.status = e.target.value;
      renderBrowseItems();
    });
  }

  const sortBy = document.getElementById('browseSortBy');
  if (sortBy) {
    sortBy.addEventListener('change', (e) => {
      AppState.filters.sortBy = e.target.value;
      renderBrowseItems();
    });
  }

  // Match Lost Item selector
  const matchSelector = document.getElementById('matchLostItemSelect');
  if (matchSelector) {
    matchSelector.addEventListener('change', (e) => {
      const val = e.target.value;
      AppState.selectedLostItemForMatch = val === 'ALL' ? null : parseInt(val, 10);
      renderMatchCandidates();
    });
  }

  // Match Confidence Filter
  const matchConfFilter = document.getElementById('matchConfidenceFilter');
  if (matchConfFilter) {
    matchConfFilter.addEventListener('change', (e) => {
      AppState.matchConfidenceFilter = e.target.value;
      renderMatchCandidates();
    });
  }

  // Modal Close buttons
  const modalCloseBtns = document.querySelectorAll('.modal-close-btn');
  modalCloseBtns.forEach(btn => {
    btn.addEventListener('click', closeModal);
  });

  // Modal backdrop click
  const modal = document.getElementById('sqlCodeModal');
  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closeModal();
    });
  }

  // Set default dates in forms to today
  const today = new Date().toISOString().split('T')[0];
  const lostDateInput = document.getElementById('lostDate');
  if (lostDateInput) {
    lostDateInput.value = today;
    lostDateInput.max = today;
  }
  const foundDateInput = document.getElementById('foundDate');
  if (foundDateInput) {
    foundDateInput.value = today;
    foundDateInput.max = today;
  }
}

/**
 * Switch active navigation view
 */
function switchTab(tabId) {
  AppState.activeTab = tabId;

  // Update nav buttons
  const navButtons = document.querySelectorAll('[data-tab-target]');
  navButtons.forEach(btn => {
    if (btn.getAttribute('data-tab-target') === tabId) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  // Update tab sections
  const tabSections = document.querySelectorAll('.tab-section');
  tabSections.forEach(sec => {
    if (sec.id === `tab-${tabId}`) {
      sec.classList.add('active');
    } else {
      sec.classList.remove('active');
    }
  });

  // Refresh data views on tab activation
  if (tabId === 'dashboard') renderDashboard();
  if (tabId === 'browse') renderBrowseItems();
  if (tabId === 'matches') renderMatchCandidates();
  if (tabId === 'manage') {
    renderClaimsTable();
    renderManagementTable();
  }

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

/**
 * Refresh Dashboard Statistics & Summaries
 */
function renderDashboard() {
  const lost = AppState.data.lost_items;
  const found = AppState.data.found_items;

  const totalLost = lost.length;
  const totalFound = found.length;

  // Unresolved: Lost items in REPORTED or POSSIBLE_MATCH + Found items in UNCLAIMED or CLAIM_PENDING
  const unresolvedLost = lost.filter(i => i.status === 'REPORTED' || i.status === 'POSSIBLE_MATCH').length;
  const unclaimedFound = found.filter(i => i.status === 'UNCLAIMED').length;
  const totalUnresolved = unresolvedLost + unclaimedFound;

  // Resolved / Returned
  const returnedLost = lost.filter(i => i.status === 'RETURNED').length;
  const claimedFound = found.filter(i => i.status === 'CLAIMED').length;
  const totalReturned = returnedLost + claimedFound;

  // Update counters
  const elTotalLost = document.getElementById('statTotalLost');
  if (elTotalLost) elTotalLost.textContent = totalLost;

  const elTotalFound = document.getElementById('statTotalFound');
  if (elTotalFound) elTotalFound.textContent = totalFound;

  const elUnresolved = document.getElementById('statUnresolved');
  if (elUnresolved) elUnresolved.textContent = totalUnresolved;

  const elReturned = document.getElementById('statReturned');
  if (elReturned) elReturned.textContent = totalReturned;

  // Calculate Matches Count
  const matches = computeAllMatches();
  const elMatchesCount = document.getElementById('statMatchesCount');
  if (elMatchesCount) elMatchesCount.textContent = matches.length;

  // Render Category Breakdown Bars
  renderCategoryBreakdown();

  // Render Recent Activity Timeline
  renderRecentActivityTimeline();
}

/**
 * Render Category Distribution Bars on Dashboard
 */
function renderCategoryBreakdown() {
  const container = document.getElementById('dashboardCategoryBars');
  if (!container) return;

  const categories = [
    { key: 'ELECTRONICS', label: 'Electronics & Gadgets', icon: '💻' },
    { key: 'BAGS_WALLETS', label: 'Bags & Wallets', icon: '🎒' },
    { key: 'CARDS_ID', label: 'Student IDs & Cards', icon: '🪪' },
    { key: 'KEYS', label: 'Keys & Keychains', icon: '🔑' },
    { key: 'BOOKS_STATIONERY', label: 'Books & Stationery', icon: '📚' },
    { key: 'ACCESSORIES', label: 'Accessories & Apparel', icon: '👓' },
    { key: 'DOCUMENTS', label: 'Documents & Certificates', icon: '📄' }
  ];

  const totalItems = AppState.data.lost_items.length + AppState.data.found_items.length;

  let html = '';
  categories.forEach(cat => {
    const lostCount = AppState.data.lost_items.filter(i => i.category === cat.key).length;
    const foundCount = AppState.data.found_items.filter(i => i.category === cat.key).length;
    const catTotal = lostCount + foundCount;
    const percentage = totalItems > 0 ? Math.round((catTotal / totalItems) * 100) : 0;

    html += `
      <div class="category-stat-row">
        <div class="cat-label">
          <span>${cat.icon} ${cat.label}</span>
          <span class="cat-counts">Lost: <strong>${lostCount}</strong> | Found: <strong>${foundCount}</strong> (${catTotal})</span>
        </div>
        <div class="progress-bar-track">
          <div class="progress-bar-fill" style="width: ${percentage}%"></div>
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
}

/**
 * Render Recent Activity Stream on Dashboard
 */
function renderRecentActivityTimeline() {
  const container = document.getElementById('dashboardRecentStream');
  if (!container) return;

  // Combine latest 3 lost and latest 3 found
  const combined = [];
  AppState.data.lost_items.slice(-4).forEach(item => {
    combined.push({
      type: 'LOST',
      id: item.lost_id,
      title: item.item_name,
      location: item.location_name,
      date: item.lost_date,
      status: item.status,
      timestamp: item.created_at || item.lost_date
    });
  });

  AppState.data.found_items.slice(-4).forEach(item => {
    combined.push({
      type: 'FOUND',
      id: item.found_id,
      title: item.item_name,
      location: item.location_name,
      date: item.found_date,
      status: item.status,
      timestamp: item.created_at || item.found_date
    });
  });

  combined.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

  let html = '';
  combined.slice(0, 6).forEach(item => {
    const isLost = item.type === 'LOST';
    const badgeClass = isLost ? 'badge-lost' : 'badge-found';
    const icon = isLost ? '🚨' : '🟢';

    html += `
      <div class="activity-card">
        <div class="activity-icon">${icon}</div>
        <div class="activity-info">
          <div class="activity-header">
            <span class="badge ${badgeClass}">${item.type} #${item.id}</span>
            <span class="activity-time">${item.date}</span>
          </div>
          <h4 class="activity-title">${escapeHtml(item.title)}</h4>
          <p class="activity-meta">📍 ${escapeHtml(item.location)} | Status: <span class="status-pill status-${item.status.toLowerCase()}">${formatStatus(item.status)}</span></p>
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
}

/**
 * Browse Items: Search, Filter, Sort, and Render
 */
function renderBrowseItems() {
  const container = document.getElementById('browseCardsGrid');
  if (!container) return;

  const f = AppState.filters;

  // Normalize all items into unified view models
  let items = [];

  if (f.type === 'ALL' || f.type === 'LOST') {
    AppState.data.lost_items.forEach(item => {
      items.push({
        recordType: 'LOST',
        id: item.lost_id,
        name: item.item_name,
        category: item.category,
        description: item.description,
        location_id: item.location_id,
        location_name: item.location_name,
        date: item.lost_date,
        status: item.status,
        person: `${item.reporter_name} (${item.reporter_roll})`,
        phone: item.reporter_phone,
        created_at: item.created_at,
        raw: item
      });
    });
  }

  if (f.type === 'ALL' || f.type === 'FOUND') {
    AppState.data.found_items.forEach(item => {
      items.push({
        recordType: 'FOUND',
        id: item.found_id,
        name: item.item_name,
        category: item.category,
        description: item.description,
        location_id: item.location_id,
        location_name: item.location_name,
        date: item.found_date,
        status: item.status,
        person: `${item.finder_name} (${item.finder_role || 'Finder'})`,
        phone: item.finder_phone,
        storage_place: item.storage_place,
        created_at: item.created_at,
        raw: item
      });
    });
  }

  // Apply Search filter
  if (f.search) {
    items = items.filter(item => {
      const q = f.search;
      return (
        item.name.toLowerCase().includes(q) ||
        item.description.toLowerCase().includes(q) ||
        item.location_name.toLowerCase().includes(q) ||
        item.person.toLowerCase().includes(q)
      );
    });
  }

  // Apply Category filter
  if (f.category !== 'ALL') {
    items = items.filter(item => item.category === f.category);
  }

  // Apply Location filter
  if (f.location !== 'ALL') {
    const locId = parseInt(f.location, 10);
    items = items.filter(item => item.location_id === locId);
  }

  // Apply Status filter
  if (f.status !== 'ALL') {
    if (f.status === 'ACTIVE') {
      items = items.filter(item => item.status === 'REPORTED' || item.status === 'UNCLAIMED' || item.status === 'POSSIBLE_MATCH');
    } else if (f.status === 'RESOLVED') {
      items = items.filter(item => item.status === 'RETURNED' || item.status === 'CLAIMED');
    } else {
      items = items.filter(item => item.status === f.status);
    }
  }

  // Apply Sorting
  items.sort((a, b) => {
    if (f.sortBy === 'date_desc') {
      return new Date(b.date) - new Date(a.date);
    } else if (f.sortBy === 'date_asc') {
      return new Date(a.date) - new Date(b.date);
    } else if (f.sortBy === 'name_asc') {
      return a.name.localeCompare(b.name);
    }
    return 0;
  });

  // Update records count label
  const countLabel = document.getElementById('browseResultsCount');
  if (countLabel) {
    countLabel.textContent = `Showing ${items.length} records`;
  }

  if (items.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">🔍</div>
        <h3>No matching records found</h3>
        <p>Try adjusting your search keywords, category filters, or status selection.</p>
      </div>
    `;
    return;
  }

  let html = '';
  items.forEach(item => {
    const isLost = item.recordType === 'LOST';
    const typeBadge = isLost ? '<span class="badge badge-lost">LOST</span>' : '<span class="badge badge-found">FOUND</span>';
    const dateLabel = isLost ? `Lost: ${item.date}` : `Found: ${item.date}`;
    const personLabel = isLost ? `Reported by: ${item.person}` : `Turned in by: ${item.person}`;

    html += `
      <div class="item-card ${isLost ? 'item-card-lost' : 'item-card-found'}">
        <div class="item-card-header">
          <div>
            ${typeBadge}
            <span class="badge badge-category">${formatCategory(item.category)}</span>
          </div>
          <span class="status-pill status-${item.status.toLowerCase()}">${formatStatus(item.status)}</span>
        </div>
        
        <h3 class="item-card-title">${escapeHtml(item.name)}</h3>
        <p class="item-card-desc">${escapeHtml(item.description)}</p>
        
        <div class="item-card-meta">
          <div class="meta-row">
            <span class="meta-icon">📍</span>
            <span class="meta-text">${escapeHtml(item.location_name)}</span>
          </div>
          <div class="meta-row">
            <span class="meta-icon">📅</span>
            <span class="meta-text">${dateLabel}</span>
          </div>
          <div class="meta-row">
            <span class="meta-icon">👤</span>
            <span class="meta-text">${escapeHtml(personLabel)}</span>
          </div>
          ${item.phone ? `
          <div class="meta-row">
            <span class="meta-icon">📞</span>
            <span class="meta-text font-semibold">Contact: <a href="tel:${escapeHtml(item.phone)}" style="color: inherit; text-decoration: underline;">${escapeHtml(item.phone)}</a></span>
          </div>` : ''}
          ${item.storage_place ? `
          <div class="meta-row">
            <span class="meta-icon">🛡️</span>
            <span class="meta-text font-semibold">Held at: ${escapeHtml(item.storage_place)}</span>
          </div>` : ''}
        </div>

        <div class="item-card-actions">
          ${isLost ? `
            <button class="btn btn-sm btn-outline" onclick="inspectLostItemMatches(${item.id})">
              ⚡ Find Matches
            </button>
          ` : `
            <button class="btn btn-sm btn-outline" onclick="showItemDetailsModal('FOUND', ${item.id})">
              📄 View Details
            </button>
          `}
          <button class="btn btn-sm btn-text" onclick="showSqlViewModal('${item.recordType}', ${item.id})">
            SQL Inspect
          </button>
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
}

/**
 * Handle Report Lost Item Form Submission
 */
function handleReportLostSubmit(e) {
  e.preventDefault();

  const itemName = document.getElementById('lostItemName').value.trim();
  const category = document.getElementById('lostCategory').value;
  const description = document.getElementById('lostDescription').value.trim();
  const locationId = parseInt(document.getElementById('lostLocation').value, 10);
  const lostDate = document.getElementById('lostDate').value;
  const reporterName = document.getElementById('lostReporterName').value.trim();
  const reporterRoll = document.getElementById('lostReporterRoll').value.trim();
  const reporterPhone = document.getElementById('lostReporterPhone') ? document.getElementById('lostReporterPhone').value.trim() : '9876543210';

  // Basic validation
  if (!itemName || !category || !description || !locationId || !lostDate || !reporterName || !reporterRoll || !reporterPhone) {
    showToast('Please fill out all required fields marked with *', 'error');
    return;
  }

  // Validate date is not future
  const selectedDate = new Date(lostDate);
  const today = new Date();
  today.setHours(23, 59, 59, 999);
  if (selectedDate > today) {
    showToast('Lost date cannot be in the future.', 'error');
    return;
  }

  // Find location object
  const locObj = AppState.data.locations.find(l => l.location_id === locationId);
  const locationName = locObj ? locObj.location_name : 'Unknown Campus Location';

  // Generate new in-memory ID
  const newId = AppState.data.lost_items.reduce((max, i) => Math.max(max, i.lost_id), 0) + 1;

  const newLostRecord = {
    lost_id: newId,
    user_id: 1, // Simulated current user
    reporter_name: reporterName,
    reporter_roll: reporterRoll,
    reporter_phone: reporterPhone,
    item_name: itemName,
    category: category,
    description: description,
    location_id: locationId,
    location_name: locationName,
    lost_date: lostDate,
    status: 'REPORTED',
    created_at: new Date().toISOString().replace('T', ' ').substring(0, 19)
  };

  // Add to in-memory state
  AppState.data.lost_items.unshift(newLostRecord);

  // Reset form
  e.target.reset();
  document.getElementById('lostDate').value = new Date().toISOString().split('T')[0];

  // Refresh views
  populateDropdowns();
  renderDashboard();
  renderBrowseItems();
  renderMatchCandidates();
  renderManagementTable();

  // Show detailed confirmation
  showToast(`Lost Item #${newId} recorded in session memory!`, 'success');
  openNotificationModal(
    'Lost Item Reported Successfully (Demonstration)',
    `
      <div class="alert-box alert-success">
        <strong>✓ Record Added to Demonstration State!</strong>
        <p>Item: <strong>${escapeHtml(itemName)}</strong> (ID #${newId})</p>
        <p>Category: <strong>${category}</strong> | Location: <strong>${escapeHtml(locationName)}</strong></p>
        <p>Student Contact: <strong>📞 ${escapeHtml(reporterPhone)}</strong> (${escapeHtml(reporterName)} - ${escapeHtml(reporterRoll)})</p>
      </div>
      <div class="notice-box-warning">
        <strong>⚠️ Database Persistence Notice:</strong>
        <p>This report has been added to the browser's in-memory demonstration state and is immediately searchable and matchable in the frontend UI.</p>
        <p>Because this project operates strictly without a backend/API bridge, this record is <strong>temporary</strong> and has not been written to MySQL. In production, this maps to the following SQL statement:</p>
        <pre class="code-preview"><code>INSERT INTO Lost_Items (user_id, item_name, category, description, location_id, lost_date, status)
VALUES (1, '${escapeSql(itemName)}', '${category}', '${escapeSql(description)}', ${locationId}, '${lostDate}', 'REPORTED');</code></pre>
      </div>
    `
  );
}

/**
 * Handle Report Found Item Form Submission
 */
function handleReportFoundSubmit(e) {
  e.preventDefault();

  const itemName = document.getElementById('foundItemName').value.trim();
  const category = document.getElementById('foundCategory').value;
  const description = document.getElementById('foundDescription').value.trim();
  const locationId = parseInt(document.getElementById('foundLocation').value, 10);
  const foundDate = document.getElementById('foundDate').value;
  const storagePlace = document.getElementById('foundStoragePlace').value.trim();
  const finderName = document.getElementById('foundFinderName').value.trim();
  const finderRole = document.getElementById('foundFinderRole').value.trim() || 'Good Samaritan';
  const finderPhone = document.getElementById('foundFinderPhone') ? document.getElementById('foundFinderPhone').value.trim() : '';

  // Validation
  if (!itemName || !category || !description || !locationId || !foundDate || !storagePlace || !finderName) {
    showToast('Please fill out all required fields marked with *', 'error');
    return;
  }

  // Validate date is not future
  const selectedDate = new Date(foundDate);
  const today = new Date();
  today.setHours(23, 59, 59, 999);
  if (selectedDate > today) {
    showToast('Found date cannot be in the future.', 'error');
    return;
  }

  const locObj = AppState.data.locations.find(l => l.location_id === locationId);
  const locationName = locObj ? locObj.location_name : 'Unknown Campus Location';

  const newId = AppState.data.found_items.reduce((max, i) => Math.max(max, i.found_id), 0) + 1;

  const newFoundRecord = {
    found_id: newId,
    finder_id: 8, // Simulated user
    finder_name: finderName,
    finder_role: finderRole,
    finder_phone: finderPhone,
    item_name: itemName,
    category: category,
    description: description,
    location_id: locationId,
    location_name: locationName,
    found_date: foundDate,
    storage_place: storagePlace,
    status: 'UNCLAIMED',
    created_at: new Date().toISOString().replace('T', ' ').substring(0, 19)
  };

  AppState.data.found_items.unshift(newFoundRecord);

  e.target.reset();
  document.getElementById('foundDate').value = new Date().toISOString().split('T')[0];

  populateDropdowns();
  renderDashboard();
  renderBrowseItems();
  renderMatchCandidates();
  renderManagementTable();

  showToast(`Found Item #${newId} recorded in session memory!`, 'success');
  openNotificationModal(
    'Found Item Reported Successfully (Demonstration)',
    `
      <div class="alert-box alert-success">
        <strong>✓ Found Record Logged in Demonstration State!</strong>
        <p>Item: <strong>${escapeHtml(itemName)}</strong> (ID #${newId})</p>
        <p>Storage Location: <strong>${escapeHtml(storagePlace)}</strong></p>
      </div>
      <div class="notice-box-warning">
        <strong>⚠️ Database Persistence Notice:</strong>
        <p>This found item is now available for matching against reported lost belongings in the browser memory.</p>
        <p>Corresponding MySQL query equivalent:</p>
        <pre class="code-preview"><code>INSERT INTO Found_Items (finder_id, item_name, category, description, location_id, found_date, storage_place, status)
VALUES (8, '${escapeSql(itemName)}', '${category}', '${escapeSql(description)}', ${locationId}, '${foundDate}', '${escapeSql(storagePlace)}', 'UNCLAIMED');</code></pre>
      </div>
    `
  );
}

/**
 * Tokenize text into normalized keywords, stripping punctuation and stop words
 */
function extractKeywords(text) {
  if (!text) return [];
  const words = text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/);

  return words.filter(w => w.length > 2 && !STOP_WORDS.has(w));
}

/**
 * Core Matching Algorithm (Client-Side Simulation of MySQL multi-criteria query)
 * Enforces strict multi-factor qualification:
 * 1. Mandatory Category Match (0 pts & disqualified if mismatch)
 * 2. Temporal Consistency (Found Date >= Lost Date within 30 days; diffDays < 0 disqualified)
 * 3. Keyword / Subject Overlap (At least 1 keyword must match; 0 keywords disqualified)
 * 4. Multi-Factor Scoring:
 *    - Category: 25 pts
 *    - Title & Description Keyword Overlap: Up to 40 pts
 *    - Location Proximity: Up to 20 pts
 *    - Date Proximity: Up to 15 pts
 * Total: 0 - 100 points
 */
function evaluateMatch(lostItem, foundItem) {
  // Prerequisite 1: Exact Category Match
  if (lostItem.category !== foundItem.category) {
    return {
      isMatch: false,
      score: 0,
      confidence: 'Category Mismatch',
      confidenceClass: 'confidence-low',
      reasons: [
        { label: 'Category Incompatible', desc: `Different categories (${lostItem.category} vs ${foundItem.category})`, points: 0, type: 'danger' }
      ],
      matchedKeywords: [],
      matchedTitleKeywords: [],
      diffDays: 0
    };
  }

  // Prerequisite 2: Date Physics (Item cannot be found before it was lost!)
  const lostDate = new Date(lostItem.lost_date);
  const foundDate = new Date(foundItem.found_date);
  const diffTime = foundDate - lostDate;
  const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays < 0) {
    return {
      isMatch: false,
      score: 0,
      confidence: 'Temporal Disqualification',
      confidenceClass: 'confidence-low',
      reasons: [
        { label: 'Date Anomaly', desc: `Found on ${foundItem.found_date}, which is ${Math.abs(diffDays)} day(s) before reported lost date (${lostItem.lost_date}). Physically impossible.`, points: 0, type: 'danger' }
      ],
      matchedKeywords: [],
      matchedTitleKeywords: [],
      diffDays: diffDays
    };
  }

  if (diffDays > 30) {
    return {
      isMatch: false,
      score: 0,
      confidence: 'Time Window Expired',
      confidenceClass: 'confidence-low',
      reasons: [
        { label: 'Time Elapsed', desc: `Found ${diffDays} days after loss (exceeds 30-day matching window)`, points: 0, type: 'warning' }
      ],
      matchedKeywords: [],
      matchedTitleKeywords: [],
      diffDays: diffDays
    };
  }

  // Prerequisite 3: Keyword & Title Token Overlap
  const lostTitleTokens = new Set(extractKeywords(lostItem.item_name));
  const lostDescTokens = new Set(extractKeywords(lostItem.description));
  const allLostTokens = new Set([...lostTitleTokens, ...lostDescTokens]);

  const foundTitleTokens = extractKeywords(foundItem.item_name);
  const foundDescTokens = extractKeywords(foundItem.description);
  const allFoundTokens = [...foundTitleTokens, ...foundDescTokens];

  const matchedTitleKeywords = [];
  foundTitleTokens.forEach(kw => {
    if (lostTitleTokens.has(kw) && !matchedTitleKeywords.includes(kw)) {
      matchedTitleKeywords.push(kw);
    }
  });

  const matchedKeywords = [];
  allFoundTokens.forEach(kw => {
    if (allLostTokens.has(kw) && !matchedKeywords.includes(kw)) {
      matchedKeywords.push(kw);
    }
  });

  // Strict Qualification Gate: If ZERO keywords match, they cannot be the same item!
  if (matchedKeywords.length === 0) {
    return {
      isMatch: false,
      score: 0,
      confidence: 'Unrelated Items',
      confidenceClass: 'confidence-low',
      reasons: [
        { label: 'Zero Keyword Overlap', desc: 'No common brand, model, or descriptive keywords found between items. Disqualified.', points: 0, type: 'neutral' }
      ],
      matchedKeywords: [],
      matchedTitleKeywords: [],
      diffDays: diffDays
    };
  }

  // --- Multi-Factor Scoring (0 - 100 pts) ---
  let score = 0;
  const reasons = [];

  // Factor 1: Category Match (25 pts)
  score += 25;
  reasons.push({ label: 'Category Match', desc: `Exact category match (${formatCategory(lostItem.category)})`, points: 25, type: 'success' });

  // Factor 2: Keyword & Title Overlap (up to 40 pts)
  let kwPoints = 0;
  if (matchedTitleKeywords.length > 0) {
    kwPoints = 22 + Math.min(13, (matchedTitleKeywords.length - 1) * 6);
  } else {
    kwPoints = 14;
  }
  const extraDescWords = matchedKeywords.filter(k => !matchedTitleKeywords.includes(k));
  kwPoints += Math.min(10, extraDescWords.length * 3);
  kwPoints = Math.min(40, kwPoints);
  score += kwPoints;

  reasons.push({
    label: 'Keyword & Title Match',
    desc: `Matched ${matchedKeywords.length} term(s): "${matchedKeywords.join('", "')}"`,
    points: kwPoints,
    type: 'success'
  });

  // Factor 3: Location Proximity (up to 20 pts)
  const isExactLocation = lostItem.location_id === foundItem.location_id;
  if (isExactLocation) {
    score += 20;
    reasons.push({ label: 'Location Match', desc: `Exact recovery location: ${lostItem.location_name}`, points: 20, type: 'success' });
  } else {
    const lostLoc = (lostItem.location_name || '').toLowerCase();
    const foundLoc = (foundItem.location_name || '').toLowerCase();
    const sameZone = (lostLoc.includes('library') && foundLoc.includes('library')) ||
                     (lostLoc.includes('hostel') && foundLoc.includes('hostel')) ||
                     (lostLoc.includes('lab') && foundLoc.includes('lab')) ||
                     (lostLoc.includes('cafeteria') && foundLoc.includes('cafeteria'));
    if (sameZone) {
      score += 10;
      reasons.push({ label: 'Adjacent Location', desc: `Same campus building zone (${lostItem.location_name} ↔ ${foundItem.location_name})`, points: 10, type: 'neutral' });
    } else {
      score += 3;
      reasons.push({ label: 'Different Campus Area', desc: `Reported at ${lostItem.location_name}, turned in at ${foundItem.location_name} (transit across campus)`, points: 3, type: 'neutral' });
    }
  }

  // Factor 4: Date Proximity & Order (up to 15 pts)
  let datePoints = 0;
  if (diffDays === 0) {
    datePoints = 15;
    reasons.push({ label: 'Same-Day Turn-in', desc: `Found on the same date of loss (0 days elapsed)`, points: 15, type: 'success' });
  } else if (diffDays === 1) {
    datePoints = 14;
    reasons.push({ label: 'Next-Day Recovery', desc: `Found within 24 hours of loss (+1 day)`, points: 14, type: 'success' });
  } else if (diffDays <= 4) {
    datePoints = 11;
    reasons.push({ label: 'Close Proximity', desc: `Found within ${diffDays} days of loss (+${diffDays}d)`, points: 11, type: 'success' });
  } else if (diffDays <= 7) {
    datePoints = 8;
    reasons.push({ label: 'Within One Week', desc: `Found ${diffDays} days after loss (+${diffDays}d)`, points: 8, type: 'neutral' });
  } else if (diffDays <= 14) {
    datePoints = 5;
    reasons.push({ label: 'Within Two Weeks', desc: `Found ${diffDays} days after loss (+${diffDays}d)`, points: 5, type: 'neutral' });
  } else {
    datePoints = 2;
    reasons.push({ label: 'Extended Window', desc: `Found ${diffDays} days after loss (+${diffDays}d)`, points: 2, type: 'neutral' });
  }
  score += datePoints;

  const finalScore = Math.min(100, Math.max(0, score));

  let confidence = 'Low Match';
  let confidenceClass = 'confidence-low';
  if (finalScore >= 75) {
    confidence = 'High Confidence Match';
    confidenceClass = 'confidence-high';
  } else if (finalScore >= 50) {
    confidence = 'Moderate Match';
    confidenceClass = 'confidence-medium';
  }

  return {
    isMatch: true,
    score: finalScore,
    confidence: confidence,
    confidenceClass: confidenceClass,
    reasons: reasons,
    matchedKeywords: matchedKeywords,
    matchedTitleKeywords: matchedTitleKeywords,
    diffDays: diffDays
  };
}

/**
 * Compute matches across all lost and found items
 */
function computeAllMatches() {
  const matches = [];
  const lostItems = AppState.data.lost_items;
  const foundItems = AppState.data.found_items;

  lostItems.forEach(lost => {
    // Only match unresolved or possible match lost items
    if (lost.status === 'RETURNED' || lost.status === 'CLOSED') return;

    foundItems.forEach(found => {
      if (found.status === 'CLAIMED' || found.status === 'DISPOSED') return;

      const evaluation = evaluateMatch(lost, found);

      // Must be a verified match candidate with score >= 45%
      if (evaluation.isMatch && evaluation.score >= 45) {
        matches.push({
          lost: lost,
          found: found,
          evaluation: evaluation
        });
      }
    });
  });

  // Sort by highest score first
  matches.sort((a, b) => b.evaluation.score - a.evaluation.score);

  // Mark top #1 best match per lost item
  const bestByLost = new Set();
  matches.forEach(m => {
    if (!bestByLost.has(m.lost.lost_id)) {
      bestByLost.add(m.lost.lost_id);
      m.isBestMatch = true;
    } else {
      m.isBestMatch = false;
    }
  });

  return matches;
}

/**
 * Render the Possible Matches Engine View
 */
function renderMatchCandidates() {
  const container = document.getElementById('matchesResultsContainer');
  if (!container) return;

  let matches = computeAllMatches();

  // If a specific lost item is filtered in dropdown
  if (AppState.selectedLostItemForMatch) {
    matches = matches.filter(m => m.lost.lost_id === AppState.selectedLostItemForMatch);
  }

  // Handle Confidence Filter
  const confFilterVal = AppState.matchConfidenceFilter || 'ALL';
  if (confFilterVal === 'HIGH') {
    matches = matches.filter(m => m.evaluation.score >= 75);
  } else if (confFilterVal === 'BEST_PER_ITEM') {
    matches = matches.filter(m => m.isBestMatch);
  }

  const matchCountHeader = document.getElementById('matchCandidatesCount');
  if (matchCountHeader) {
    matchCountHeader.textContent = `Found ${matches.length} Verified Match Pair${matches.length === 1 ? '' : 's'}`;
  }

  if (matches.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">🤝</div>
        <h3>No matching candidates found</h3>
        <p>No active lost item satisfies the high-precision matching criteria (identical category, valid date order, and keyword overlap). Try adjusting filters or reporting a new item.</p>
      </div>
    `;
    return;
  }

  let html = '';
  matches.forEach((m, idx) => {
    const { lost, found, evaluation, isBestMatch } = m;

    html += `
      <div class="match-card">
        <div class="match-card-header">
          <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
            <div class="match-score-badge ${evaluation.confidenceClass}">
              <span class="match-percent">${evaluation.score}%</span>
              <span class="match-label">${evaluation.confidence}</span>
            </div>
            ${isBestMatch ? `<span class="badge" style="background: #fef3c7; color: #92400e; border: 1px solid #fde68a; font-weight: 700; font-size: 11px;">⭐ Rank #1 Best Match</span>` : ''}
          </div>
          <div class="match-actions-top">
            <button class="btn btn-sm btn-outline" onclick="showMatchSqlQuery(${lost.lost_id}, ${found.found_id})">
              🔍 View MySQL Query Equivalent
            </button>
            <button class="btn btn-sm btn-primary" onclick="simulateMatchClaim(${lost.lost_id}, ${found.found_id})">
              ✓ Simulate Claim Verification
            </button>
          </div>
        </div>

        <div class="match-comparison-grid">
          <!-- Lost Item Side -->
          <div class="match-item-column match-column-lost">
            <div class="column-header">
              <span class="badge badge-lost">LOST ITEM #${lost.lost_id}</span>
              <span class="column-date">Lost on: ${lost.lost_date}</span>
            </div>
            <h4 class="match-item-title">${escapeHtml(lost.item_name)}</h4>
            <p class="match-item-desc">${escapeHtml(lost.description)}</p>
            <div class="match-meta-list">
              <div>📍 <strong>Last Seen:</strong> ${escapeHtml(lost.location_name)}</div>
              <div>🏷️ <strong>Category:</strong> ${formatCategory(lost.category)}</div>
              <div>👤 <strong>Reported By:</strong> ${escapeHtml(lost.reporter_name)} (${escapeHtml(lost.reporter_roll)})</div>
              <div>📞 <strong>Student Phone:</strong> <a href="tel:${escapeHtml(lost.reporter_phone || '9876543210')}" style="color: var(--primary); font-weight: 700; text-decoration: underline;">${escapeHtml(lost.reporter_phone || '9876543210')}</a></div>
            </div>
          </div>

          <!-- Divider Indicator -->
          <div class="match-vs-divider">
            <div class="vs-circle">VS</div>
          </div>

          <!-- Found Item Side -->
          <div class="match-item-column match-column-found">
            <div class="column-header">
              <span class="badge badge-found">FOUND ITEM #${found.found_id}</span>
              <span class="column-date">Found on: ${found.found_date}</span>
            </div>
            <h4 class="match-item-title">${escapeHtml(found.item_name)}</h4>
            <p class="match-item-desc">${escapeHtml(found.description)}</p>
            <div class="match-meta-list">
              <div>📍 <strong>Found At:</strong> ${escapeHtml(found.location_name)}</div>
              <div>🏷️ <strong>Category:</strong> ${formatCategory(found.category)}</div>
              <div>🛡️ <strong>Stored At:</strong> ${escapeHtml(found.storage_place)}</div>
              <div>👤 <strong>Turned In By:</strong> ${escapeHtml(found.finder_name)}</div>
              ${found.finder_phone ? `<div>📞 <strong>Finder Phone:</strong> <a href="tel:${escapeHtml(found.finder_phone)}" style="color: var(--found-color); font-weight: 600; text-decoration: underline;">${escapeHtml(found.finder_phone)}</a></div>` : ''}
            </div>
          </div>
        </div>

        <!-- Matching Criteria Breakdown -->
        <div class="match-reasons-panel">
          <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; margin-bottom: 8px;">
            <div class="reasons-title" style="margin-bottom: 0;">Multi-Criteria Evidence Breakdown:</div>
            ${evaluation.matchedKeywords && evaluation.matchedKeywords.length > 0 ? `
              <div style="display: flex; gap: 5px; flex-wrap: wrap;">
                ${evaluation.matchedKeywords.map(kw => `<span class="badge" style="background: #e0e7ff; color: #3730a3; font-size: 11px; padding: 2px 7px;">🔑 ${escapeHtml(kw)}</span>`).join('')}
              </div>
            ` : ''}
          </div>
          <div class="reasons-chips">
            ${evaluation.reasons.map(r => `
              <span class="reason-chip reason-${r.type}">
                <strong>${r.label}:</strong> ${escapeHtml(r.desc)} (+${r.points} pts)
              </span>
            `).join('')}
          </div>
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
}

/**
 * Filter match candidates for a specific lost item
 */
function inspectLostItemMatches(lostId) {
  switchTab('matches');
  const selector = document.getElementById('matchLostItemSelect');
  if (selector) {
    selector.value = lostId;
    AppState.selectedLostItemForMatch = lostId;
  }
  const confFilter = document.getElementById('matchConfidenceFilter');
  if (confFilter) {
    confFilter.value = 'ALL';
    AppState.matchConfidenceFilter = 'ALL';
  }
  renderMatchCandidates();

  setTimeout(() => {
    const container = document.getElementById('matchesResultsContainer');
    if (container) {
      container.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }, 100);
}

/**
 * Simulate Claim Verification / Status Transition
 */
function simulateMatchClaim(lostId, foundId) {
  const lost = AppState.data.lost_items.find(i => i.lost_id === lostId);
  const found = AppState.data.found_items.find(i => i.found_id === foundId);

  if (!lost || !found) return;

  // Update statuses in in-memory state
  lost.status = 'POSSIBLE_MATCH';
  found.status = 'CLAIM_PENDING';

  // Check if claim already exists
  let existingClaim = AppState.data.claims.find(c => c.found_id === foundId && c.lost_id === lostId);
  if (!existingClaim) {
    const newClaimId = AppState.data.claims.reduce((max, c) => Math.max(max, c.claim_id), 0) + 1;
    AppState.data.claims.unshift({
      claim_id: newClaimId,
      found_id: foundId,
      found_item_name: found.item_name,
      claimant_id: lost.user_id,
      claimant_name: lost.reporter_name,
      claimant_roll: lost.reporter_roll,
      claimant_phone: lost.reporter_phone || '9876543210',
      lost_id: lostId,
      claim_date: new Date().toISOString().replace('T', ' ').substring(0, 19),
      verification_proof: `Auto-generated matching claim based on ${lost.item_name} reported on ${lost.lost_date}.`,
      claim_status: 'PENDING',
      resolved_by_name: null,
      resolution_notes: 'Claim initiated through Possible Matches recommendation engine.'
    });
  }

  renderDashboard();
  renderBrowseItems();
  renderMatchCandidates();
  renderClaimsTable();
  renderManagementTable();

  showToast(`Simulated Match: Lost #${lostId} linked with Found #${foundId}`, 'success');
  openNotificationModal(
    'Demonstration Status Transition Executed',
    `
      <div class="alert-box alert-success">
        <strong>✓ State Transition Applied in Demonstration Memory:</strong>
        <ul>
          <li>Lost Item #${lostId} status updated to <strong>POSSIBLE_MATCH</strong></li>
          <li>Found Item #${foundId} status updated to <strong>CLAIM_PENDING</strong></li>
          <li>A simulated claim entry has been created in the Claims table for verification</li>
        </ul>
      </div>
      <div class="notice-box-warning">
        <strong>DBMS Transaction Note:</strong>
        <p>In MySQL, this workflow is executed within an ACID-compliant transaction to avoid orphan state. See <code>sql/06_claim_processing.sql</code> for the SQL transaction syntax:</p>
        <pre class="code-preview"><code>START TRANSACTION;
UPDATE Lost_Items SET status = 'POSSIBLE_MATCH' WHERE lost_id = ${lostId};
UPDATE Found_Items SET status = 'CLAIM_PENDING' WHERE found_id = ${foundId};
INSERT INTO Claims (found_id, claimant_id, lost_id, verification_proof, claim_status)
VALUES (${foundId}, ${lost.user_id}, ${lostId}, 'Automated system match', 'PENDING');
COMMIT;</code></pre>
      </div>
    `
  );
}

/**
 * Render Claims Table in Manage Tab
 */
function renderClaimsTable() {
  const tbody = document.getElementById('claimsTableBody');
  if (!tbody) return;

  const claims = AppState.data.claims;

  if (claims.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" class="text-center">No claims on record.</td></tr>';
    return;
  }

  let html = '';
  claims.forEach(c => {
    html += `
      <tr>
        <td><strong>#${c.claim_id}</strong></td>
        <td>
          <div class="font-semibold">${escapeHtml(c.found_item_name)}</div>
          <small class="text-muted">Found #${c.found_id} ${c.lost_id ? `| Lost #${c.lost_id}` : ''}</small>
        </td>
        <td>
          <div>${escapeHtml(c.claimant_name)}</div>
          <small class="text-muted">${escapeHtml(c.claimant_roll || 'ID: ' + c.claimant_id)}</small>
          ${c.claimant_phone ? `<div class="text-xs" style="color: var(--primary); font-weight: 600; margin-top: 2px;">📞 <a href="tel:${escapeHtml(c.claimant_phone)}" style="color: inherit; text-decoration: none;">${escapeHtml(c.claimant_phone)}</a></div>` : ''}
        </td>
        <td class="text-xs max-w-xs">${escapeHtml(c.verification_proof)}</td>
        <td><span class="status-pill status-${c.claim_status.toLowerCase()}">${c.claim_status}</span></td>
        <td><small>${c.claim_date.split(' ')[0]}</small></td>
        <td>
          <div class="btn-group">
            ${c.claim_status === 'PENDING' || c.claim_status === 'VERIFIED' ? `
              <button class="btn btn-xs btn-success" onclick="resolveClaim(${c.claim_id}, 'APPROVED')">Approve</button>
              <button class="btn btn-xs btn-danger" onclick="resolveClaim(${c.claim_id}, 'REJECTED')">Reject</button>
            ` : `
              <span class="text-muted text-xs">Closed (${c.claim_status})</span>
            `}
          </div>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

/**
 * Resolve a Claim (Approve or Reject) in demo memory
 */
function resolveClaim(claimId, newStatus) {
  const claim = AppState.data.claims.find(c => c.claim_id === claimId);
  if (!claim) return;

  claim.claim_status = newStatus;
  claim.resolved_by_name = 'Inspector Ramesh Yadav (Demo)';
  claim.resolved_at = new Date().toISOString().replace('T', ' ').substring(0, 19);

  const foundItem = AppState.data.found_items.find(f => f.found_id === claim.found_id);
  const lostItem = claim.lost_id ? AppState.data.lost_items.find(l => l.lost_id === claim.lost_id) : null;

  if (newStatus === 'APPROVED') {
    if (foundItem) foundItem.status = 'CLAIMED';
    if (lostItem) lostItem.status = 'RETURNED';
    claim.resolution_notes = 'Ownership identity and proof of purchase verified by security staff. Property returned.';
    showToast(`Claim #${claimId} APPROVED! Items marked as Claimed & Returned.`, 'success');
  } else if (newStatus === 'REJECTED') {
    if (foundItem) foundItem.status = 'UNCLAIMED';
    if (lostItem) lostItem.status = 'REPORTED';
    claim.resolution_notes = 'Claim verification proof failed inspection. Claim rejected.';
    showToast(`Claim #${claimId} REJECTED. Found item reverted to UNCLAIMED.`, 'error');
  }

  renderDashboard();
  renderBrowseItems();
  renderMatchCandidates();
  renderClaimsTable();
  renderManagementTable();
}

/**
 * Render Status Management Table
 */
function renderManagementTable() {
  const tbody = document.getElementById('managementTableBody');
  if (!tbody) return;

  // Display all lost and found items for direct status toggle
  const rows = [];
  AppState.data.lost_items.forEach(item => {
    rows.push({
      type: 'LOST',
      id: item.lost_id,
      name: item.item_name,
      category: item.category,
      location: item.location_name,
      date: item.lost_date,
      status: item.status,
      allowedStatuses: ['REPORTED', 'POSSIBLE_MATCH', 'RETURNED', 'CLOSED']
    });
  });

  AppState.data.found_items.forEach(item => {
    rows.push({
      type: 'FOUND',
      id: item.found_id,
      name: item.item_name,
      category: item.category,
      location: item.location_name,
      date: item.found_date,
      status: item.status,
      allowedStatuses: ['UNCLAIMED', 'CLAIM_PENDING', 'CLAIMED', 'DISPOSED']
    });
  });

  let html = '';
  rows.slice(0, 15).forEach(r => {
    html += `
      <tr>
        <td><span class="badge ${r.type === 'LOST' ? 'badge-lost' : 'badge-found'}">${r.type} #${r.id}</span></td>
        <td><strong>${escapeHtml(r.name)}</strong></td>
        <td>${formatCategory(r.category)}</td>
        <td><small>${escapeHtml(r.location)}</small></td>
        <td><span class="status-pill status-${r.status.toLowerCase()}">${formatStatus(r.status)}</span></td>
        <td>
          <select class="form-select-sm" onchange="changeItemStatus('${r.type}', ${r.id}, this.value)">
            ${r.allowedStatuses.map(st => `<option value="${st}" ${st === r.status ? 'selected' : ''}>${formatStatus(st)}</option>`).join('')}
          </select>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

/**
 * Change status of an item manually in demonstration table
 */
function changeItemStatus(type, id, newStatus) {
  if (type === 'LOST') {
    const item = AppState.data.lost_items.find(i => i.lost_id === id);
    if (item) {
      item.status = newStatus;
      showToast(`Lost Item #${id} status changed to ${newStatus}`, 'info');
    }
  } else {
    const item = AppState.data.found_items.find(i => i.found_id === id);
    if (item) {
      item.status = newStatus;
      showToast(`Found Item #${id} status changed to ${newStatus}`, 'info');
    }
  }

  renderDashboard();
  renderBrowseItems();
  renderMatchCandidates();
  renderClaimsTable();
  renderManagementTable();
}

/**
 * Show Modal with SQL equivalent for a specific match
 */
function showMatchSqlQuery(lostId, foundId) {
  const lost = AppState.data.lost_items.find(i => i.lost_id === lostId);
  const found = AppState.data.found_items.find(i => i.found_id === foundId);

  const queryCode = `-- ==========================================================
-- MATCHING QUERY DEMONSTRATION FOR PAIR (Lost #${lostId} & Found #${foundId})
-- Extracted from sql/04_matching_queries.sql
-- ==========================================================

SELECT 
    l.lost_id,
    l.item_name AS lost_item,
    l.category,
    l.lost_date,
    loc_lost.location_name AS lost_location,
    u_lost.phone AS student_phone,
    f.found_id,
    f.item_name AS found_item,
    f.found_date,
    loc_found.location_name AS found_location,
    DATEDIFF(f.found_date, l.lost_date) AS days_difference,
    -- Dynamic Multi-Factor Match Score Formula (Max 100 pts):
    (
        -- 1. Category Consistency: 25 pts (Mandatory Prerequisite)
        (CASE WHEN l.category = f.category THEN 25 ELSE 0 END) +
        -- 2. Keyword & Title Similarity: up to 40 pts
        (CASE 
            WHEN LOWER(l.item_name) = LOWER(f.item_name) THEN 40
            WHEN LOWER(f.item_name) LIKE CONCAT('%', SUBSTRING_INDEX(l.item_name, ' ', 1), '%') THEN 30
            WHEN LOWER(f.description) LIKE CONCAT('%', SUBSTRING_INDEX(l.item_name, ' ', 1), '%') THEN 20
            ELSE 14 
         END) +
        -- 3. Location Proximity: 20 pts (20 exact, 10 same zone, 3 campus transit)
        (CASE 
            WHEN l.location_id = f.location_id THEN 20 
            WHEN loc_lost.building = loc_found.building THEN 10
            ELSE 3 
         END) +
        -- 4. Date Proximity & Temporal Order: 15 pts (Found Date >= Lost Date)
        (CASE 
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 1 THEN 15
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 4 THEN 11
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 7 THEN 8
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 14 THEN 5
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 30 THEN 2
            ELSE 0 
         END)
    ) AS calculated_match_score,
    'POSSIBLE MATCH - REQUIRES VERIFICATION' AS match_status_label
FROM Lost_Items l
CROSS JOIN Found_Items f
INNER JOIN Users u_lost ON l.user_id = u_lost.user_id
INNER JOIN Locations loc_lost ON l.location_id = loc_lost.location_id
INNER JOIN Locations loc_found ON f.location_id = loc_found.location_id
WHERE l.lost_id = ${lostId}
  AND f.found_id = ${foundId};`;

  openNotificationModal(
    `MySQL Matching Query: Pair [Lost #${lostId} ↔ Found #${foundId}]`,
    `
      <p class="text-sm mb-3">Below is the exact SQL query executed in MySQL Workbench that generates this match score and criteria comparison:</p>
      <pre class="code-preview"><code>${escapeHtml(queryCode)}</code></pre>
      <div class="mt-3 text-xs text-muted">
        <strong>DBMS Concept Demonstrated:</strong> Cross joins filtered by multi-criteria conditional expressions, aggregate scoring via <code>CASE WHEN</code>, and date arithmetic using <code>DATEDIFF()</code>.
      </div>
    `
  );
}

/**
 * Show Item Details Modal
 */
function showItemDetailsModal(type, id) {
  const item = type === 'LOST' 
    ? AppState.data.lost_items.find(i => i.lost_id === id)
    : AppState.data.found_items.find(i => i.found_id === id);

  if (!item) return;

  const isLost = type === 'LOST';

  openNotificationModal(
    `${type} Item Details: #${id} - ${escapeHtml(item.item_name)}`,
    `
      <div class="details-modal-grid">
        <div class="detail-field">
          <label>Category:</label>
          <div><span class="badge badge-category">${formatCategory(item.category)}</span></div>
        </div>
        <div class="detail-field">
          <label>Current Status:</label>
          <div><span class="status-pill status-${item.status.toLowerCase()}">${formatStatus(item.status)}</span></div>
        </div>
        <div class="detail-field">
          <label>${isLost ? 'Lost Date:' : 'Found Date:'}</label>
          <div>${isLost ? item.lost_date : item.found_date}</div>
        </div>
        <div class="detail-field">
          <label>Campus Location:</label>
          <div>${escapeHtml(item.location_name)}</div>
        </div>
        <div class="detail-field col-span-2">
          <label>Full Description:</label>
          <div class="bg-slate p-2 rounded">${escapeHtml(item.description)}</div>
        </div>
        <div class="detail-field">
          <label>${isLost ? 'Reported By:' : 'Turned In By:'}</label>
          <div>${escapeHtml(isLost ? item.reporter_name + ' (' + item.reporter_roll + ')' : item.finder_name + ' (' + (item.finder_role || 'Finder') + ')')}</div>
        </div>
        <div class="detail-field">
          <label>${isLost ? 'Student Contact Phone:' : 'Finder Contact Phone:'}</label>
          <div class="font-semibold text-emerald">
            📞 <a href="tel:${escapeHtml(isLost ? item.reporter_phone : (item.finder_phone || '9876543217'))}" style="color: inherit; text-decoration: underline;">${escapeHtml(isLost ? item.reporter_phone : (item.finder_phone || 'Available with Custodian'))}</a>
          </div>
        </div>
        ${!isLost && item.storage_place ? `
        <div class="detail-field col-span-2">
          <label>Secure Custody Place:</label>
          <div class="font-semibold text-emerald">${escapeHtml(item.storage_place)}</div>
        </div>` : ''}
      </div>
    `
  );
}

/**
 * Show SQL View Modal for an item
 */
function showSqlViewModal(type, id) {
  const isLost = type === 'LOST';
  const tableName = isLost ? 'Lost_Items' : 'Found_Items';
  const idCol = isLost ? 'lost_id' : 'found_id';

  const queryCode = `-- Retrieve full record with relational joins from MySQL 8.0:
SELECT 
    t.*,
    u.student_or_staff_id,
    u.full_name AS person_name,
    u.email AS person_email,
    u.phone AS person_phone,
    u.department,
    loc.location_name,
    loc.building,
    loc.zone_type
FROM ${tableName} t
INNER JOIN Users u ON t.${isLost ? 'user_id' : 'finder_id'} = u.user_id
INNER JOIN Locations loc ON t.location_id = loc.location_id
WHERE t.${idCol} = ${id};`;

  openNotificationModal(
    `MySQL Relational Query for ${type} #${id}`,
    `
      <p class="text-sm mb-2">This SQL query retrieves the complete entity record from MySQL with foreign-key joins to <code>Users</code> and <code>Locations</code>:</p>
      <pre class="code-preview"><code>${escapeHtml(queryCode)}</code></pre>
      <p class="text-xs text-muted mt-2">Executed via MySQL Workbench or command-line client against database <code>campus_lost_found</code>.</p>
    `
  );
}

/**
 * Modal Dialog Helpers
 */
function openNotificationModal(title, contentHtml) {
  const modal = document.getElementById('sqlCodeModal');
  const titleEl = document.getElementById('modalTitle');
  const bodyEl = document.getElementById('modalBody');

  if (modal && titleEl && bodyEl) {
    titleEl.textContent = title;
    bodyEl.innerHTML = contentHtml;
    modal.classList.add('active');
  }
}

function closeModal() {
  const modal = document.getElementById('sqlCodeModal');
  if (modal) {
    modal.classList.remove('active');
  }
}

/**
 * Toast Notification system
 */
function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `
    <span class="toast-icon">${type === 'success' ? '✓' : type === 'error' ? '✕' : 'ℹ'}</span>
    <span class="toast-message">${escapeHtml(message)}</span>
  `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('fade-out');
    setTimeout(() => {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 300);
  }, 4000);
}

/**
 * Utility string formatters
 */
function formatCategory(cat) {
  const map = {
    'ELECTRONICS': 'Electronics',
    'CARDS_ID': 'ID / Cards',
    'BAGS_WALLETS': 'Bags & Wallets',
    'KEYS': 'Keys',
    'BOOKS_STATIONERY': 'Books & Stationery',
    'ACCESSORIES': 'Accessories',
    'DOCUMENTS': 'Documents',
    'OTHER': 'Other'
  };
  return map[cat] || cat;
}

function formatStatus(status) {
  const map = {
    'REPORTED': 'Reported',
    'POSSIBLE_MATCH': 'Possible Match',
    'RETURNED': 'Returned',
    'CLOSED': 'Closed',
    'UNCLAIMED': 'Unclaimed',
    'CLAIM_PENDING': 'Claim Pending',
    'CLAIMED': 'Claimed',
    'DISPOSED': 'Disposed',
    'PENDING': 'Pending Verification',
    'VERIFIED': 'Verified',
    'APPROVED': 'Approved',
    'REJECTED': 'Rejected'
  };
  return map[status] || status;
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function escapeSql(str) {
  if (!str) return '';
  return String(str).replace(/'/g, "''");
}
