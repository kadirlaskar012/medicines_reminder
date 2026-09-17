#!/usr/bin/env python3
"""
MediRemind - Local Offline Database Admin Dashboard
===================================================
A lightweight, zero-dependency offline admin panel to inspect, search,
and export MediRemind's SQLite database directly in your browser.

Usage:
    python tool/admin_dashboard.py [--port 8080] [--db path/to/mediremind.db]
"""

import http.server
import socketserver
import json
import os
import sys
import sqlite3
import webbrowser
import subprocess
import argparse
from urllib.parse import parse_qs, urlparse

# Default paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
DEFAULT_DB_LOCATIONS = [
    os.path.join(SCRIPT_DIR, "mediremind.db"),
    os.path.join(PROJECT_DIR, "mediremind.db"),
]

PACKAGE_NAME = "com.mediremind.app.medicines_reminder"

def find_adb():
    """Locate adb.exe from PATH or Android SDK default location."""
    # 1. Try PATH
    try:
        res = subprocess.run(["adb", "version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode == 0:
            return "adb"
    except Exception:
        pass

    # 2. Try LOCALAPPDATA Android SDK
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if local_app_data:
        sdk_adb = os.path.join(local_app_data, "Android", "Sdk", "platform-tools", "adb.exe")
        if os.path.exists(sdk_adb):
            return sdk_adb

    return None

def pull_database_from_adb(target_path):
    """Pull mediremind.db from connected Android phone via ADB run-as."""
    adb_bin = find_adb()
    if not adb_bin:
        return False, "ADB executable not found. Make sure Android SDK platform-tools is installed."

    try:
        # Check connected devices
        dev_res = subprocess.run([adb_bin, "devices"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        lines = [l.strip() for l in dev_res.stdout.strip().split("\n")[1:] if l.strip() and not l.startswith("*")]
        if not lines:
            return False, "No Android device connected. Please connect your phone via USB with USB Debugging enabled."

        cmd = f'"{adb_bin}" exec-out run-as {PACKAGE_NAME} cat databases/mediremind.db'
        with open(target_path, "wb") as f:
            proc = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE, shell=True)

        if os.path.exists(target_path) and os.path.getsize(target_path) > 100:
            # Verify SQLite header
            with open(target_path, "rb") as f:
                header = f.read(16)
                if header.startswith(b"SQLite format 3"):
                    return True, f"Successfully pulled latest database ({os.path.getsize(target_path):,} bytes) from phone!"

        return False, f"Could not extract mediremind.db via ADB. App may not be debuggable or databases/mediremind.db does not exist yet."
    except Exception as e:
        return False, f"ADB pull error: {e}"

def get_db_path(custom_path=None):
    if custom_path and os.path.exists(custom_path):
        return custom_path
    for loc in DEFAULT_DB_LOCATIONS:
        if os.path.exists(loc):
            return loc
    return DEFAULT_DB_LOCATIONS[0]

def query_db(db_path):
    """Read all tables from SQLite DB and return as structured dictionary."""
    data = {
        "status": "ok",
        "db_path": db_path,
        "db_exists": os.path.exists(db_path),
        "db_size": os.path.getsize(db_path) if os.path.exists(db_path) else 0,
        "profiles": [],
        "medicines": [],
        "reminders": [],
        "intake_records": []
    }

    if not os.path.exists(db_path):
        return data

    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()

        # Check existing tables
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in cur.fetchall()]

        if "profiles" in tables:
            cur.execute("SELECT * FROM profiles")
            data["profiles"] = [dict(r) for r in cur.fetchall()]

        if "medicines" in tables:
            cur.execute("SELECT * FROM medicines ORDER BY createdAt DESC")
            data["medicines"] = [dict(r) for r in cur.fetchall()]

        if "reminder_times" in tables:
            cur.execute("SELECT * FROM reminder_times ORDER BY hour, minute")
            data["reminders"] = [dict(r) for r in cur.fetchall()]

        if "intake_records" in tables:
            cur.execute("SELECT * FROM intake_records ORDER BY recordedAt DESC LIMIT 200")
            data["intake_records"] = [dict(r) for r in cur.fetchall()]

        conn.close()
    except Exception as e:
        data["status"] = "error"
        data["error"] = str(e)

    return data

HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MediRemind - Offline Database Admin Panel</title>
<style>
  :root {
    --bg-primary: #0B132B;
    --bg-secondary: #1C2541;
    --card-bg: #1F293D;
    --accent: #0D9488;
    --accent-hover: #0F766E;
    --text-primary: #F8FAFC;
    --text-secondary: #94A3B8;
    --border: #334155;
    --success: #10B981;
    --warning: #F59E0B;
    --danger: #EF4444;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--bg-primary);
    color: var(--text-primary);
    line-height: 1.5;
    padding: 24px;
  }
  .container { max-width: 1300px; margin: 0 auto; }
  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-bottom: 20px;
    border-bottom: 1px solid var(--border);
    margin-bottom: 24px;
    flex-wrap: wrap;
    gap: 16px;
  }
  .brand { display: flex; align-items: center; gap: 12px; }
  .logo-icon {
    width: 44px; height: 44px;
    background: linear-gradient(135deg, #0D9488, #3B82F6);
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    font-size: 22px;
  }
  h1 { font-size: 22px; font-weight: 800; letter-spacing: -0.5px; }
  .subtitle { font-size: 12px; color: var(--text-secondary); }
  .header-actions { display: flex; gap: 10px; align-items: center; }
  .btn {
    padding: 9px 16px;
    border-radius: 10px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    border: none;
    display: inline-flex; align-items: center; gap: 8px;
    transition: all 0.2s;
  }
  .btn-primary { background: var(--accent); color: white; }
  .btn-primary:hover { background: var(--accent-hover); }
  .btn-secondary { background: var(--card-bg); color: var(--text-primary); border: 1px solid var(--border); }
  .btn-secondary:hover { background: var(--border); }
  
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 16px;
    margin-bottom: 24px;
  }
  .stat-card {
    background: var(--card-bg);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 16px 20px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
  .stat-val { font-size: 26px; font-weight: 800; color: var(--text-primary); }
  .stat-label { font-size: 12px; color: var(--text-secondary); margin-top: 2px; }
  .stat-icon { font-size: 28px; opacity: 0.8; }

  .notice-banner {
    background: rgba(13, 148, 136, 0.12);
    border: 1px solid rgba(13, 148, 136, 0.4);
    border-radius: 12px;
    padding: 12px 18px;
    font-size: 13px;
    margin-bottom: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 10px;
  }

  .tabs-nav {
    display: flex;
    gap: 8px;
    border-bottom: 1px solid var(--border);
    margin-bottom: 20px;
    overflow-x: auto;
  }
  .tab-btn {
    padding: 10px 18px;
    background: transparent;
    border: none;
    color: var(--text-secondary);
    font-size: 14px;
    font-weight: 700;
    cursor: pointer;
    border-bottom: 3px solid transparent;
    display: flex; align-items: center; gap: 8px;
    transition: all 0.2s;
  }
  .tab-btn.active {
    color: var(--accent);
    border-bottom-color: var(--accent);
  }
  .tab-badge {
    background: var(--border);
    padding: 2px 7px;
    border-radius: 20px;
    font-size: 11px;
    color: var(--text-primary);
  }

  .search-bar {
    display: flex;
    gap: 12px;
    margin-bottom: 16px;
    flex-wrap: wrap;
  }
  .search-input {
    flex: 1;
    min-width: 260px;
    padding: 10px 16px;
    background: var(--card-bg);
    border: 1px solid var(--border);
    border-radius: 10px;
    color: var(--text-primary);
    font-size: 13px;
    outline: none;
  }
  .search-input:focus { border-color: var(--accent); }

  .table-wrapper {
    background: var(--card-bg);
    border: 1px solid var(--border);
    border-radius: 14px;
    overflow-x: auto;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
    text-align: left;
  }
  th {
    background: rgba(15, 23, 42, 0.6);
    padding: 14px 16px;
    color: var(--text-secondary);
    font-weight: 700;
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.5px;
    border-bottom: 1px solid var(--border);
  }
  td {
    padding: 14px 16px;
    border-bottom: 1px solid rgba(51, 65, 85, 0.4);
    vertical-align: middle;
  }
  tr:last-child td { border-bottom: none; }
  tr:hover { background: rgba(255, 255, 255, 0.02); }

  .badge {
    display: inline-block;
    padding: 3px 8px;
    border-radius: 6px;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
  }
  .badge-success { background: rgba(16, 185, 129, 0.15); color: #34D399; }
  .badge-warning { background: rgba(245, 158, 11, 0.15); color: #FBBF24; }
  .badge-danger { background: rgba(239, 68, 68, 0.15); color: #F87171; }
  .badge-primary { background: rgba(13, 148, 136, 0.2); color: #2DD4BF; }
  .badge-muted { background: rgba(148, 163, 184, 0.15); color: #94A3B8; }

  .empty-state {
    text-align: center;
    padding: 48px 24px;
    color: var(--text-secondary);
  }
  .empty-state-icon { font-size: 40px; margin-bottom: 10px; }

  footer {
    margin-top: 36px;
    text-align: center;
    font-size: 12px;
    color: var(--text-secondary);
    border-top: 1px solid var(--border);
    padding-top: 20px;
  }
</style>
</head>
<body>

<div class="container">
  <header>
    <div class="brand">
      <div class="logo-icon">💊</div>
      <div>
        <h1>MediRemind Database Browser</h1>
        <div class="subtitle" id="dbStatus">Loading offline SQLite database...</div>
      </div>
    </div>
    <div class="header-actions">
      <button class="btn btn-secondary" onclick="exportJSON()">📥 Export JSON</button>
      <button class="btn btn-secondary" onclick="syncFromADB()" id="syncBtn">🔄 Sync from Phone (ADB)</button>
      <button class="btn btn-primary" onclick="loadData()">⟳ Refresh</button>
    </div>
  </header>

  <div class="notice-banner" id="bannerMsg" style="display:none;"></div>

  <div class="stats-grid">
    <div class="stat-card">
      <div>
        <div class="stat-val" id="statMeds">0</div>
        <div class="stat-label">Total Medicines</div>
      </div>
      <div class="stat-icon">💊</div>
    </div>
    <div class="stat-card">
      <div>
        <div class="stat-val" id="statReminders">0</div>
        <div class="stat-label">Active Reminders</div>
      </div>
      <div class="stat-icon">⏰</div>
    </div>
    <div class="stat-card">
      <div>
        <div class="stat-val" id="statRecords">0</div>
        <div class="stat-label">Intake Logs Recorded</div>
      </div>
      <div class="stat-icon">📋</div>
    </div>
    <div class="stat-card">
      <div>
        <div class="stat-val" id="statProfiles">0</div>
        <div class="stat-label">Family Profiles</div>
      </div>
      <div class="stat-icon">👤</div>
    </div>
  </div>

  <div class="tabs-nav">
    <button class="tab-btn active" onclick="switchTab('medicines')">💊 Medicines <span class="tab-badge" id="badgeMeds">0</span></button>
    <button class="tab-btn" onclick="switchTab('reminders')">⏰ Reminder Times <span class="tab-badge" id="badgeReminders">0</span></button>
    <button class="tab-btn" onclick="switchTab('intake')">📋 Intake History <span class="tab-badge" id="badgeIntake">0</span></button>
    <button class="tab-btn" onclick="switchTab('profiles')">👥 Family Profiles <span class="tab-badge" id="badgeProfiles">0</span></button>
  </div>

  <div class="search-bar">
    <input type="text" id="filterInput" class="search-input" placeholder="Search by name, dosage, or status..." oninput="applyFilter()">
  </div>

  <!-- Tab 1: Medicines -->
  <div id="tab-medicines" class="tab-content">
    <div class="table-wrapper">
      <table id="tableMeds">
        <thead>
          <tr>
            <th>Medicine</th>
            <th>Type</th>
            <th>Unit</th>
            <th>Stock Inventory</th>
            <th>Refill Alert</th>
            <th>Instruction</th>
            <th>Course Duration</th>
            <th>Expiry</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody id="tbodyMeds"></tbody>
      </table>
    </div>
  </div>

  <!-- Tab 2: Reminders -->
  <div id="tab-reminders" class="tab-content" style="display:none;">
    <div class="table-wrapper">
      <table id="tableReminders">
        <thead>
          <tr>
            <th>Medicine ID</th>
            <th>Scheduled Time</th>
            <th>Repeat Days</th>
            <th>Alarm Mode</th>
            <th>Notification ID</th>
          </tr>
        </thead>
        <tbody id="tbodyReminders"></tbody>
      </table>
    </div>
  </div>

  <!-- Tab 3: Intake History -->
  <div id="tab-intake" class="tab-content" style="display:none;">
    <div class="table-wrapper">
      <table id="tableIntake">
        <thead>
          <tr>
            <th>Scheduled Time</th>
            <th>Medicine ID</th>
            <th>Status</th>
            <th>Recorded At</th>
            <th>Notes</th>
          </tr>
        </thead>
        <tbody id="tbodyIntake"></tbody>
      </table>
    </div>
  </div>

  <!-- Tab 4: Profiles -->
  <div id="tab-profiles" class="tab-content" style="display:none;">
    <div class="table-wrapper">
      <table id="tableProfiles">
        <thead>
          <tr>
            <th>Avatar</th>
            <th>Profile Name</th>
            <th>Relationship</th>
            <th>Age</th>
            <th>Profile ID</th>
          </tr>
        </thead>
        <tbody id="tbodyProfiles"></tbody>
      </table>
    </div>
  </div>

  <footer>
    MediRemind Local Offline Admin Browser · Zero External Dependencies · Running on Localhost
  </footer>
</div>

<script>
let currentData = null;
let currentTab = 'medicines';

const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

function formatDays(daysStr) {
  if (!daysStr) return 'Every day';
  try {
    const arr = typeof daysStr === 'string' ? daysStr.split(',').map(Number) : daysStr;
    if (arr.length === 7) return 'Every day';
    return arr.map(d => weekdayNames[(d - 1) % 7]).join(', ');
  } catch(e) {
    return daysStr;
  }
}

function switchTab(tabId) {
  currentTab = tabId;
  document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(tc => tc.style.display = 'none');
  
  event.currentTarget.classList.add('active');
  document.getElementById('tab-' + tabId).style.display = 'block';
  applyFilter();
}

async function loadData() {
  try {
    const res = await fetch('/api/data');
    const data = await res.json();
    currentData = data;

    const dbLoc = data.db_path || 'mediremind.db';
    const dbSize = (data.db_size / 1024).toFixed(1);
    document.getElementById('dbStatus').textContent = data.db_exists 
      ? `Connected to ${dbLoc} (${dbSize} KB)`
      : `DB file not found at ${dbLoc}. Click 'Sync from Phone' to pull from device.`;

    document.getElementById('statMeds').textContent = (data.medicines || []).length;
    document.getElementById('statReminders').textContent = (data.reminders || []).length;
    document.getElementById('statRecords').textContent = (data.intake_records || []).length;
    document.getElementById('statProfiles').textContent = (data.profiles || []).length;

    document.getElementById('badgeMeds').textContent = (data.medicines || []).length;
    document.getElementById('badgeReminders').textContent = (data.reminders || []).length;
    document.getElementById('badgeIntake').textContent = (data.intake_records || []).length;
    document.getElementById('badgeProfiles').textContent = (data.profiles || []).length;

    renderMedicines(data.medicines || []);
    renderReminders(data.reminders || []);
    renderIntake(data.intake_records || []);
    renderProfiles(data.profiles || []);
  } catch (err) {
    showNotice('Failed to fetch data: ' + err.message, true);
  }
}

function renderMedicines(meds) {
  const tbody = document.getElementById('tbodyMeds');
  if (!meds.length) {
    tbody.innerHTML = '<tr><td colspan="9" class="empty-state"><div class="empty-state-icon">💊</div>No medicines found in database.</td></tr>';
    return;
  }

  tbody.innerHTML = meds.map(m => {
    const unit = m.unit || (m.type === 'syrup' ? 'ml' : (m.type === 'inhaler' ? 'Puffs' : 'Tablets'));
    const isLow = m.currentStock <= m.refillThreshold;
    const stockBadge = m.currentStock <= 0
      ? `<span class="badge badge-danger">Out of stock (0 ${unit})</span>`
      : isLow 
        ? `<span class="badge badge-warning">${m.currentStock} ${unit}</span>`
        : `<span class="badge badge-success">${m.currentStock} ${unit}</span>`;

    const statusBadge = m.isActive == 1 
      ? '<span class="badge badge-success">Active</span>'
      : '<span class="badge badge-muted">Paused</span>';

    const courseStr = m.durationDays > 0 ? `${m.durationDays} days` : 'Ongoing / Chronic';
    const expiryStr = m.expiryDate ? m.expiryDate.split('T')[0] : '—';

    return `<tr>
      <td><strong>${escapeHtml(m.name)}</strong><br><span style="color:#94A3B8; font-size:11px;">${escapeHtml(m.dosage || '')}</span></td>
      <td><span class="badge badge-primary">${escapeHtml(m.type || 'tablet')}</span></td>
      <td><strong>${escapeHtml(unit)}</strong></td>
      <td>${stockBadge}</td>
      <td>≤ ${m.refillThreshold} ${escapeHtml(unit)}</td>
      <td>${escapeHtml(m.instruction || 'afterMeal')}</td>
      <td>${courseStr}</td>
      <td>${expiryStr}</td>
      <td>${statusBadge}</td>
    </tr>`;
  }).join('');
}

function renderReminders(reminders) {
  const tbody = document.getElementById('tbodyReminders');
  if (!reminders.length) {
    tbody.innerHTML = '<tr><td colspan="5" class="empty-state"><div class="empty-state-icon">⏰</div>No reminders scheduled in database.</td></tr>';
    return;
  }

  tbody.innerHTML = reminders.map(r => {
    const timeStr = `${String(r.hour).padStart(2, '0')}:${String(r.minute).padStart(2, '0')}`;
    const alarmBadge = r.isAlarm == 1 
      ? '<span class="badge badge-success">Full Alarm</span>'
      : '<span class="badge badge-muted">Notification</span>';

    return `<tr>
      <td><code>${escapeHtml(r.medicineId)}</code></td>
      <td><strong>${timeStr}</strong></td>
      <td>${formatDays(r.daysOfWeek)}</td>
      <td>${alarmBadge}</td>
      <td><code>${r.notificationId}</code></td>
    </tr>`;
  }).join('');
}

function renderIntake(records) {
  const tbody = document.getElementById('tbodyIntake');
  if (!records.length) {
    tbody.innerHTML = '<tr><td colspan="5" class="empty-state"><div class="empty-state-icon">📋</div>No intake history logged yet.</td></tr>';
    return;
  }

  tbody.innerHTML = records.map(r => {
    const statusClass = r.status === 'taken' ? 'badge-success' : (r.status === 'skipped' ? 'badge-danger' : 'badge-warning');
    const schedStr = `${r.scheduledDate} ${String(r.scheduledHour).padStart(2, '0')}:${String(r.scheduledMinute).padStart(2, '0')}`;
    const recStr = r.recordedAt ? r.recordedAt.replace('T', ' ').split('.')[0] : '—';

    return `<tr>
      <td><strong>${schedStr}</strong></td>
      <td><code>${escapeHtml(r.medicineId)}</code></td>
      <td><span class="badge ${statusClass}">${escapeHtml(r.status)}</span></td>
      <td style="color:#94A3B8; font-size:12px;">${recStr}</td>
      <td>${escapeHtml(r.notes || '—')}</td>
    </tr>`;
  }).join('');
}

function renderProfiles(profiles) {
  const tbody = document.getElementById('tbodyProfiles');
  if (!profiles.length) {
    tbody.innerHTML = '<tr><td colspan="5" class="empty-state"><div class="empty-state-icon">👤</div>No profiles found.</td></tr>';
    return;
  }

  tbody.innerHTML = profiles.map(p => `<tr>
    <td style="font-size:24px;">${escapeHtml(p.avatarEmoji || '👤')}</td>
    <td><strong>${escapeHtml(p.name)}</strong></td>
    <td><span class="badge badge-primary">${escapeHtml(p.relation)}</span></td>
    <td>${p.age ? p.age + ' years' : '—'}</td>
    <td><code>${escapeHtml(p.id)}</code></td>
  </tr>`).join('');
}

function applyFilter() {
  const query = (document.getElementById('filterInput').value || '').toLowerCase().trim();
  if (!currentData) return;

  if (currentTab === 'medicines') {
    const filtered = (currentData.medicines || []).filter(m => 
      (m.name || '').toLowerCase().includes(query) ||
      (m.dosage || '').toLowerCase().includes(query) ||
      (m.type || '').toLowerCase().includes(query)
    );
    renderMedicines(filtered);
  } else if (currentTab === 'reminders') {
    const filtered = (currentData.reminders || []).filter(r => 
      (r.medicineId || '').toLowerCase().includes(query)
    );
    renderReminders(filtered);
  } else if (currentTab === 'intake') {
    const filtered = (currentData.intake_records || []).filter(i => 
      (i.medicineId || '').toLowerCase().includes(query) ||
      (i.status || '').toLowerCase().includes(query)
    );
    renderIntake(filtered);
  } else if (currentTab === 'profiles') {
    const filtered = (currentData.profiles || []).filter(p => 
      (p.name || '').toLowerCase().includes(query) ||
      (p.relation || '').toLowerCase().includes(query)
    );
    renderProfiles(filtered);
  }
}

async function syncFromADB() {
  const btn = document.getElementById('syncBtn');
  btn.disabled = true;
  btn.textContent = '🔄 Pulling from Phone...';

  try {
    const res = await fetch('/api/sync_adb', { method: 'POST' });
    const result = await res.json();
    showNotice(result.message, !result.success);
    if (result.success) {
      await loadData();
    }
  } catch (err) {
    showNotice('ADB sync request failed: ' + err.message, true);
  } finally {
    btn.disabled = false;
    btn.textContent = '🔄 Sync from Phone (ADB)';
  }
}

function exportJSON() {
  if (!currentData) return;
  const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(currentData, null, 2));
  const downloadAnchor = document.createElement('a');
  downloadAnchor.setAttribute("href", dataStr);
  downloadAnchor.setAttribute("download", `mediremind_db_export_${new Date().toISOString().split('T')[0]}.json`);
  document.body.appendChild(downloadAnchor);
  downloadAnchor.click();
  downloadAnchor.remove();
}

function showNotice(msg, isError = false) {
  const b = document.getElementById('bannerMsg');
  b.style.display = 'block';
  b.style.background = isError ? 'rgba(239, 68, 68, 0.15)' : 'rgba(16, 185, 129, 0.15)';
  b.style.borderColor = isError ? '#EF4444' : '#10B981';
  b.style.color = isError ? '#F87171' : '#34D399';
  b.innerHTML = `<span>${escapeHtml(msg)}</span><button onclick="document.getElementById('bannerMsg').style.display='none'" style="background:none; border:none; color:inherit; cursor:pointer; font-weight:bold;">✕</button>`;
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

window.onload = loadData;
</script>
</body>
</html>
"""

class AdminDashboardHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress verbose standard HTTP request logging
        pass

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
        elif path == "/api/data":
            db_path = get_db_path(self.server.custom_db_path)
            data = query_db(db_path)
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/api/sync_adb":
            target_path = get_db_path(self.server.custom_db_path)
            success, msg = pull_database_from_adb(target_path)
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps({"success": success, "message": msg}, ensure_ascii=False).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

def main():
    parser = argparse.ArgumentParser(description="MediRemind Local Offline Admin Dashboard")
    parser.add_argument("--port", type=int, default=8080, help="Port to run web server on (default: 8080)")
    parser.add_argument("--db", type=str, default=None, help="Path to local mediremind.db SQLite file")
    parser.add_argument("--no-browser", action="store_true", help="Do not automatically open browser")
    parser.add_argument("--test", action="store_true", help="Run self-test and exit immediately")
    args = parser.parse_args()

    db_path = get_db_path(args.db)

    if args.test:
        print("[TEST] Running database query test...")
        data = query_db(db_path)
        print(f"[TEST] Status: {data['status']}, Found {len(data['medicines'])} medicines, {len(data['reminders'])} reminders.")
        return

    # Attempt to auto-pull if db doesn't exist yet and device is connected
    if not os.path.exists(db_path):
        adb = find_adb()
        if adb:
            print("[INFO] No local database found. Checking connected device...")
            ok, msg = pull_database_from_adb(db_path)
            if ok:
                print(f"[SUCCESS] {msg}")

    # Start server
    port = args.port
    max_retries = 10
    httpd = None

    for p in range(port, port + max_retries):
        try:
            httpd = socketserver.TCPServer(("127.0.0.1", p), AdminDashboardHandler)
            port = p
            break
        except OSError:
            continue

    if not httpd:
        print(f"[ERROR] Could not bind to port {args.port} or next {max_retries} ports.")
        sys.exit(1)

    httpd.custom_db_path = args.db
    url = f"http://localhost:{port}"

    print("=" * 65)
    print("  💊 MediRemind - Local Offline Admin Dashboard")
    print(f"  🌐 Running at: {url}")
    print(f"  📁 Database:   {os.path.abspath(db_path)}")
    print("=" * 65)
    print("Press Ctrl+C to stop server.\n")

    if not args.no_browser:
        try:
            webbrowser.open(url)
        except Exception:
            pass

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping Admin Dashboard server. Goodbye!")
        httpd.server_close()

if __name__ == "__main__":
    main()
