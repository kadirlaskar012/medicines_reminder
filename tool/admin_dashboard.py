#!/usr/bin/env python3
"""
MediRemind - Local & Cloud Admin Dashboard
==========================================
A lightweight, zero-dependency local admin panel to inspect, search,
and monitor MediRemind user accounts, medicines, reminders, and intake logs
directly in your browser.

Integrates with Supabase Cloud REST API with automatic offline caching,
plus local SQLite fallback.

Usage:
    python tool/admin_dashboard.py [--port 8080] [--db path/to/mediremind.db] [--no-browser]
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
import datetime
from urllib.parse import parse_qs, urlparse
import urllib.request
import urllib.error

# Project paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CACHE_FILE = os.path.join(SCRIPT_DIR, "mediremind_cache.json")
DEFAULT_DB_LOCATIONS = [
    os.path.join(SCRIPT_DIR, "mediremind.db"),
    os.path.join(PROJECT_DIR, "mediremind.db"),
]

PACKAGE_NAME = "com.mediremind.app.medicines_reminder"

# Supabase Credentials (from lib/core/constants/supabase_config.dart)
SUPABASE_URL = "https://ybjkranvgdsntsqqtcng.supabase.co"
SUPABASE_ANON_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InliamtyYW52Z2RzbnRzcXF0Y25nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkyOTA1NTYsImV4cCI6MjEwNDg2NjU1Nn0."
    "ndPVXa0bHRVUqTqldkqvx77OTYiaL4VhFQ0LXKIHnxQ"
)

def fetch_supabase_table(table_name, timeout=8):
    """Fetch a table from Supabase REST API using standard urllib."""
    url = f"{SUPABASE_URL}/rest/v1/{table_name}?select=*"
    req = urllib.request.Request(
        url,
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Accept": "application/json",
            "User-Agent": "MediRemindAdminDashboard/2.0"
        }
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            content = resp.read().decode("utf-8")
            return json.loads(content), None
    except Exception as e:
        return None, str(e)

def fetch_all_supabase_data():
    """Fetch all relevant tables from Supabase Cloud."""
    data = {
        "status": "ok",
        "data_source": "supabase_cloud",
        "synced_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "supabase_url": SUPABASE_URL,
        "users": [],
        "medicines": [],
        "reminders": [],
        "dose_logs": [],
        "pin_requests": [],
        "error": None
    }

    # Fetch app_users
    users, err = fetch_supabase_table("app_users")
    if err and users is None:
        data["status"] = "error"
        data["error"] = f"Supabase connection failed: {err}"
        return data
    data["users"] = users or []

    # Fetch user_medicines
    meds, _ = fetch_supabase_table("user_medicines")
    data["medicines"] = meds or []

    # Fetch user_reminders
    reminders, _ = fetch_supabase_table("user_reminders")
    data["reminders"] = reminders or []

    # Fetch user_dose_logs
    logs, _ = fetch_supabase_table("user_dose_logs")
    data["dose_logs"] = logs or []

    # Fetch pin_reset_requests
    pin_reqs, _ = fetch_supabase_table("pin_reset_requests")
    data["pin_requests"] = pin_reqs or []

    # Cache locally so offline mode works seamlessly
    try:
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"[WARN] Failed to write local cache: {e}")

    return data

def load_cached_data():
    """Load data from local JSON cache if offline."""
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                data["data_source"] = "supabase_cache"
                data["status"] = "ok"
                return data
        except Exception as e:
            print(f"[WARN] Failed to read cache: {e}")
    return None

def find_adb():
    """Locate adb.exe from PATH or Android SDK default location."""
    try:
        res = subprocess.run(["adb", "version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode == 0:
            return "adb"
    except Exception:
        pass

    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if local_app_data:
        sdk_adb = os.path.join(local_app_data, "Android", "Sdk", "platform-tools", "adb.exe")
        if os.path.exists(sdk_adb):
            return sdk_adb

    return None

def pull_database_from_adb(target_path):
    """Safely pull mediremind.db from connected Android phone via ADB run-as."""
    adb_bin = find_adb()
    if not adb_bin:
        return False, "ADB executable not found. Make sure Android SDK platform-tools is installed."

    try:
        dev_res = subprocess.run([adb_bin, "devices"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        lines = [l.strip() for l in dev_res.stdout.strip().split("\n")[1:] if l.strip() and not l.startswith("*")]
        if not lines:
            return False, "No Android device connected. Please connect your phone via USB with USB Debugging enabled."

        cmd = f'"{adb_bin}" exec-out run-as {PACKAGE_NAME} cat databases/mediremind.db'
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        stdout_data = proc.stdout

        if stdout_data.startswith(b"SQLite format 3"):
            with open(target_path, "wb") as f:
                f.write(stdout_data)
            return True, f"Successfully pulled database from device ({len(stdout_data):,} bytes)!"
        else:
            err_msg = stdout_data.decode("utf-8", errors="ignore").strip()
            if "not debuggable" in err_msg:
                return False, "Phone app is a release build (non-debuggable). Please use the live Cloud Sync button to view your Supabase data!"
            return False, f"Could not pull SQLite DB from device: {err_msg[:100]}"
    except Exception as e:
        return False, f"ADB pull error: {e}"

def get_db_path(custom_path=None):
    if custom_path and os.path.exists(custom_path):
        return custom_path
    for loc in DEFAULT_DB_LOCATIONS:
        if os.path.exists(loc):
            return loc
    return DEFAULT_DB_LOCATIONS[0]

def query_local_sqlite(db_path):
    """Read tables from local SQLite DB if valid."""
    data = {
        "status": "ok",
        "data_source": "local_sqlite",
        "db_path": db_path,
        "db_exists": os.path.exists(db_path),
        "db_size": os.path.getsize(db_path) if os.path.exists(db_path) else 0,
        "users": [],
        "medicines": [],
        "reminders": [],
        "dose_logs": [],
        "profiles": []
    }

    if not os.path.exists(db_path):
        return data

    try:
        # Check SQLite magic header
        with open(db_path, "rb") as f:
            header = f.read(16)
            if not header.startswith(b"SQLite format 3"):
                data["status"] = "invalid_sqlite"
                return data

        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()

        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in cur.fetchall()]

        if "profiles" in tables:
            cur.execute("SELECT * FROM profiles")
            data["profiles"] = [dict(r) for r in cur.fetchall()]

        if "medicines" in tables:
            cur.execute("SELECT * FROM medicines ORDER BY createdAt DESC")
            raw_meds = [dict(r) for r in cur.fetchall()]
            # Normalize column names to match Supabase schema
            for m in raw_meds:
                data["medicines"].append({
                    "id": m.get("id"),
                    "name": m.get("name"),
                    "dosage": m.get("dosage"),
                    "type": m.get("type"),
                    "instruction": m.get("instruction"),
                    "current_stock": m.get("currentStock"),
                    "unit": m.get("unit"),
                    "is_active": bool(m.get("isActive", 1)),
                    "duration_days": m.get("durationDays", 0),
                    "start_date": m.get("startDate"),
                    "end_date": m.get("endDate"),
                    "expiry_date": m.get("expiryDate"),
                    "email": m.get("email") or "local_device",
                    "phone_number": m.get("phoneNumber") or "",
                    "reminders_json": m.get("remindersJson") or "[]"
                })

        if "reminder_times" in tables:
            cur.execute("SELECT * FROM reminder_times ORDER BY hour, minute")
            data["reminders"] = [dict(r) for r in cur.fetchall()]

        if "intake_records" in tables:
            cur.execute("SELECT * FROM intake_records ORDER BY recordedAt DESC LIMIT 200")
            raw_logs = [dict(r) for r in cur.fetchall()]
            for l in raw_logs:
                data["dose_logs"].append({
                    "id": l.get("id"),
                    "medicine_id": l.get("medicineId"),
                    "scheduled_time": f"{l.get('scheduledDate')} {l.get('scheduledHour', 0):02d}:{l.get('scheduledMinute', 0):02d}",
                    "status": l.get("status"),
                    "taken_at": l.get("recordedAt"),
                    "email": l.get("email") or "local_device"
                })

        conn.close()
    except Exception as e:
        data["status"] = "error"
        data["error"] = str(e)

    return data

def get_combined_data(custom_db_path=None, force_cloud=False):
    """
    Unified data aggregator:
    1. Try live Supabase cloud fetch.
    2. If cloud fails, try cached Supabase JSON.
    3. If local SQLite exists, merge or fallback.
    """
    cloud_data = None
    if force_cloud or True:
        cloud_data = fetch_all_supabase_data()
        if cloud_data.get("status") == "ok":
            return cloud_data

    # Supabase failed or offline; check cache
    cached = load_cached_data()
    if cached:
        cached["offline_notice"] = "Displaying offline cached data from Supabase (Internet unavailable)."
        return cached

    # Check local SQLite
    db_path = get_db_path(custom_db_path)
    sqlite_data = query_local_sqlite(db_path)
    if sqlite_data.get("medicines") or sqlite_data.get("profiles"):
        return sqlite_data

    # Return empty cloud result with error
    if cloud_data:
        return cloud_data

    return {
        "status": "empty",
        "data_source": "none",
        "users": [],
        "medicines": [],
        "reminders": [],
        "dose_logs": [],
        "pin_requests": [],
        "error": "No database found and unable to reach Supabase Cloud."
    }

HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MediRemind - Cloud & Offline Admin Portal</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --bg-main: #0B1120;
    --bg-card: #151F32;
    --bg-card-hover: #1A2740;
    --bg-inner: #0E1726;
    --border: #24344D;
    --border-light: #334968;
    --text-main: #F1F5F9;
    --text-muted: #94A3B8;
    --text-subtle: #64748B;
    --primary: #0EA5E9;
    --primary-glow: rgba(14, 165, 233, 0.25);
    --primary-hover: #0284C7;
    --accent: #10B981;
    --accent-glow: rgba(16, 185, 129, 0.2);
    --warning: #F59E0B;
    --danger: #EF4444;
    --danger-glow: rgba(239, 68, 68, 0.2);
    --purple: #8B5CF6;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--bg-main);
    color: var(--text-main);
    line-height: 1.5;
    padding: 24px;
    min-height: 100vh;
  }
  .container { max-width: 1400px; margin: 0 auto; }
  
  /* Header */
  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-bottom: 24px;
    border-bottom: 1px solid var(--border);
    margin-bottom: 24px;
    flex-wrap: wrap;
    gap: 16px;
  }
  .brand { display: flex; align-items: center; gap: 14px; }
  .logo-icon {
    width: 48px; height: 48px;
    background: linear-gradient(135deg, #0EA5E9 0%, #10B981 100%);
    border-radius: 14px;
    display: flex; align-items: center; justify-content: center;
    font-size: 26px;
    box-shadow: 0 4px 20px var(--primary-glow);
  }
  h1 { font-size: 24px; font-weight: 800; letter-spacing: -0.6px; }
  .status-tag {
    display: inline-flex; align-items: center; gap: 6px;
    font-size: 12px; font-weight: 600; padding: 3px 10px;
    border-radius: 20px; margin-top: 4px;
  }
  .status-tag.cloud { background: rgba(16, 185, 129, 0.15); color: #34D399; border: 1px solid rgba(16, 185, 129, 0.3); }
  .status-tag.cached { background: rgba(245, 158, 11, 0.15); color: #FBBF24; border: 1px solid rgba(245, 158, 11, 0.3); }
  .status-tag.offline { background: rgba(239, 68, 68, 0.15); color: #F87171; border: 1px solid rgba(239, 68, 68, 0.3); }
  .status-dot { width: 7px; height: 7px; border-radius: 50%; background: currentColor; animation: pulse 2s infinite; }
  @keyframes pulse { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(0.8); } }

  .header-actions { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
  .btn {
    padding: 10px 18px;
    border-radius: 10px;
    font-size: 13px;
    font-weight: 700;
    cursor: pointer;
    border: none;
    display: inline-flex; align-items: center; gap: 8px;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    font-family: inherit;
  }
  .btn:hover { transform: translateY(-1px); }
  .btn:active { transform: translateY(0); }
  .btn-primary {
    background: linear-gradient(135deg, #0EA5E9, #0284C7);
    color: white;
    box-shadow: 0 4px 14px var(--primary-glow);
  }
  .btn-primary:hover { background: linear-gradient(135deg, #0284C7, #0369A1); }
  .btn-secondary {
    background: var(--bg-card);
    color: var(--text-main);
    border: 1px solid var(--border);
  }
  .btn-secondary:hover { background: var(--border); border-color: var(--border-light); }
  .btn-sm { padding: 6px 12px; font-size: 12px; border-radius: 8px; }

  /* Notice Banner */
  .notice-banner {
    border-radius: 12px;
    padding: 14px 20px;
    font-size: 13px;
    margin-bottom: 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
  }

  /* Stats Grid */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 16px;
    margin-bottom: 28px;
  }
  .stat-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 20px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    transition: border-color 0.2s, transform 0.2s;
    cursor: pointer;
  }
  .stat-card:hover {
    border-color: var(--primary);
    transform: translateY(-2px);
  }
  .stat-val { font-size: 32px; font-weight: 800; color: var(--text-main); line-height: 1.1; }
  .stat-label { font-size: 13px; color: var(--text-muted); margin-top: 4px; font-weight: 500; }
  .stat-sub { font-size: 11px; color: var(--text-subtle); margin-top: 2px; }
  .stat-icon {
    width: 52px; height: 52px;
    border-radius: 14px;
    display: flex; align-items: center; justify-content: center;
    font-size: 26px;
  }
  .icon-blue { background: rgba(14, 165, 233, 0.12); color: #38BDF8; }
  .icon-green { background: rgba(16, 185, 129, 0.12); color: #34D399; }
  .icon-purple { background: rgba(139, 92, 246, 0.12); color: #A78BFA; }
  .icon-amber { background: rgba(245, 158, 11, 0.12); color: #FBBF24; }

  /* Navigation Tabs */
  .tabs-nav {
    display: flex;
    gap: 8px;
    border-bottom: 1px solid var(--border);
    margin-bottom: 20px;
    overflow-x: auto;
    padding-bottom: 2px;
  }
  .tab-btn {
    padding: 12px 20px;
    background: transparent;
    border: none;
    color: var(--text-muted);
    font-size: 14px;
    font-weight: 700;
    cursor: pointer;
    border-bottom: 3px solid transparent;
    display: flex; align-items: center; gap: 8px;
    transition: all 0.2s;
    font-family: inherit;
    white-space: nowrap;
  }
  .tab-btn:hover { color: var(--text-main); }
  .tab-btn.active {
    color: var(--primary);
    border-bottom-color: var(--primary);
  }
  .tab-badge {
    background: var(--bg-inner);
    border: 1px solid var(--border);
    padding: 2px 8px;
    border-radius: 20px;
    font-size: 11px;
    color: var(--text-main);
  }
  .tab-btn.active .tab-badge {
    background: var(--primary-glow);
    border-color: var(--primary);
    color: var(--primary);
  }

  /* Search & Filter Bar */
  .filter-bar {
    display: flex;
    gap: 12px;
    margin-bottom: 20px;
    flex-wrap: wrap;
    align-items: center;
  }
  .search-box {
    flex: 1;
    min-width: 280px;
    position: relative;
  }
  .search-input {
    width: 100%;
    padding: 11px 16px 11px 40px;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 12px;
    color: var(--text-main);
    font-size: 13px;
    outline: none;
    font-family: inherit;
    transition: border-color 0.2s;
  }
  .search-input:focus { border-color: var(--primary); box-shadow: 0 0 0 3px var(--primary-glow); }
  .search-icon {
    position: absolute; left: 14px; top: 50%; transform: translateY(-50%);
    color: var(--text-subtle); font-size: 15px; pointer-events: none;
  }
  .select-filter {
    padding: 11px 16px;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 12px;
    color: var(--text-main);
    font-size: 13px;
    font-family: inherit;
    outline: none;
    cursor: pointer;
    min-width: 180px;
  }
  .select-filter:focus { border-color: var(--primary); }

  /* Table Styling */
  .table-wrapper {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.25);
    overflow-x: auto;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
    text-align: left;
  }
  th {
    background: var(--bg-inner);
    padding: 14px 18px;
    color: var(--text-muted);
    font-weight: 700;
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.6px;
    border-bottom: 1px solid var(--border);
  }
  td {
    padding: 16px 18px;
    border-bottom: 1px solid rgba(36, 52, 77, 0.6);
    vertical-align: middle;
  }
  tr:last-child td { border-bottom: none; }
  tr:hover { background: rgba(255, 255, 255, 0.02); }

  /* Badges */
  .badge {
    display: inline-flex; align-items: center; gap: 4px;
    padding: 4px 10px;
    border-radius: 8px;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }
  .badge-success { background: rgba(16, 185, 129, 0.15); color: #34D399; border: 1px solid rgba(16, 185, 129, 0.3); }
  .badge-warning { background: rgba(245, 158, 11, 0.15); color: #FBBF24; border: 1px solid rgba(245, 158, 11, 0.3); }
  .badge-danger { background: rgba(239, 68, 68, 0.15); color: #F87171; border: 1px solid rgba(239, 68, 68, 0.3); }
  .badge-primary { background: rgba(14, 165, 233, 0.15); color: #38BDF8; border: 1px solid rgba(14, 165, 233, 0.3); }
  .badge-purple { background: rgba(139, 92, 246, 0.15); color: #C4B5FD; border: 1px solid rgba(139, 92, 246, 0.3); }
  .badge-muted { background: rgba(100, 116, 139, 0.15); color: #94A3B8; border: 1px solid rgba(100, 116, 139, 0.3); }

  /* User chip */
  .user-chip {
    display: inline-flex;
    align-items: center;
    gap: 8px;
  }
  .user-avatar {
    width: 34px; height: 34px;
    border-radius: 10px;
    background: linear-gradient(135deg, #0EA5E9, #8B5CF6);
    display: flex; align-items: center; justify-content: center;
    font-weight: 800; font-size: 13px; color: white;
  }
  .user-details { display: flex; flex-direction: column; }
  .user-name { font-weight: 700; color: var(--text-main); }
  .user-email { font-size: 11px; color: var(--text-muted); }

  /* Medicine color dot */
  .med-color {
    width: 10px; height: 10px; border-radius: 50%; display: inline-block; margin-right: 6px;
  }

  /* Empty state */
  .empty-state {
    text-align: center;
    padding: 60px 24px;
    color: var(--text-muted);
  }
  .empty-state-icon { font-size: 48px; margin-bottom: 12px; opacity: 0.7; }
  .empty-state-title { font-size: 16px; font-weight: 700; color: var(--text-main); margin-bottom: 6px; }

  /* Modal */
  .modal-overlay {
    position: fixed; inset: 0; background: rgba(0, 0, 0, 0.75);
    backdrop-filter: blur(4px); display: none; align-items: center; justify-content: center;
    z-index: 1000; padding: 20px;
  }
  .modal-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 20px;
    max-width: 650px; width: 100%;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.6);
    overflow: hidden;
  }
  .modal-header {
    padding: 20px 24px;
    border-bottom: 1px solid var(--border);
    display: flex; justify-content: space-between; align-items: center;
  }
  .modal-title { font-size: 17px; font-weight: 800; }
  .modal-body { padding: 24px; max-height: 70vh; overflow-y: auto; }
  .modal-close {
    background: none; border: none; color: var(--text-muted);
    font-size: 20px; cursor: pointer; padding: 4px;
  }
  .modal-close:hover { color: var(--text-main); }
  .detail-row {
    display: flex; justify-content: space-between; padding: 10px 0;
    border-bottom: 1px solid rgba(36, 52, 77, 0.4); font-size: 13px;
  }
  .detail-label { color: var(--text-muted); font-weight: 600; }
  .detail-val { color: var(--text-main); font-weight: 500; text-align: right; word-break: break-all; max-width: 65%; }

  footer {
    margin-top: 40px;
    text-align: center;
    font-size: 12px;
    color: var(--text-subtle);
    border-top: 1px solid var(--border);
    padding-top: 24px;
  }
</style>
</head>
<body>

<div class="container">
  <!-- Header -->
  <header>
    <div class="brand">
      <div class="logo-icon">💊</div>
      <div>
        <div style="display:flex; align-items:center; gap:10px;">
          <h1>MediRemind Admin Portal</h1>
          <span class="status-tag cloud" id="statusBadge">
            <span class="status-dot"></span> <span id="statusText">Connecting...</span>
          </span>
        </div>
        <div style="font-size: 12px; color: var(--text-muted); margin-top: 3px;" id="statusSub">
          Inspecting user registrations & medicines across Cloud & Offline storage
        </div>
      </div>
    </div>
    <div class="header-actions">
      <button class="btn btn-secondary" onclick="exportJSON()">📥 Export JSON</button>
      <button class="btn btn-secondary" onclick="syncFromADB()" id="syncAdbBtn">📱 Sync ADB</button>
      <button class="btn btn-primary" onclick="loadData(true)" id="refreshBtn">🔄 Sync Cloud (Supabase)</button>
    </div>
  </header>

  <!-- Notice Banner -->
  <div class="notice-banner" id="bannerMsg" style="display:none;"></div>

  <!-- Stats Grid -->
  <div class="stats-grid">
    <div class="stat-card" onclick="switchTab('users')">
      <div>
        <div class="stat-val" id="statUsers">0</div>
        <div class="stat-label">Registered Accounts</div>
        <div class="stat-sub" id="statUsersSub">Email & Phone accounts</div>
      </div>
      <div class="stat-icon icon-blue">👥</div>
    </div>
    <div class="stat-card" onclick="switchTab('medicines')">
      <div>
        <div class="stat-val" id="statMeds">0</div>
        <div class="stat-label">Total Medicines</div>
        <div class="stat-sub" id="statMedsSub">Added by users</div>
      </div>
      <div class="stat-icon icon-green">💊</div>
    </div>
    <div class="stat-card" onclick="switchTab('reminders')">
      <div>
        <div class="stat-val" id="statReminders">0</div>
        <div class="stat-label">Reminders & Alarms</div>
        <div class="stat-sub" id="statRemindersSub">Scheduled intake slots</div>
      </div>
      <div class="stat-icon icon-purple">⏰</div>
    </div>
    <div class="stat-card" onclick="switchTab('logs')">
      <div>
        <div class="stat-val" id="statLogs">0</div>
        <div class="stat-label">Dose Intake Logs</div>
        <div class="stat-sub" id="statLogsSub">Taken / Skipped history</div>
      </div>
      <div class="stat-icon icon-amber">📋</div>
    </div>
  </div>

  <!-- Tabs Nav -->
  <div class="tabs-nav">
    <button class="tab-btn active" id="tabBtn-users" onclick="switchTab('users')">
      👥 User Accounts <span class="tab-badge" id="badgeUsers">0</span>
    </button>
    <button class="tab-btn" id="tabBtn-medicines" onclick="switchTab('medicines')">
      💊 Medicines by User <span class="tab-badge" id="badgeMeds">0</span>
    </button>
    <button class="tab-btn" id="tabBtn-reminders" onclick="switchTab('reminders')">
      ⏰ Reminder Schedules <span class="tab-badge" id="badgeReminders">0</span>
    </button>
    <button class="tab-btn" id="tabBtn-logs" onclick="switchTab('logs')">
      📋 Dose Intake History <span class="tab-badge" id="badgeLogs">0</span>
    </button>
    <button class="tab-btn" id="tabBtn-pin" onclick="switchTab('pin')">
      🔐 Security & PIN Requests <span class="tab-badge" id="badgePin">0</span>
    </button>
  </div>

  <!-- Search & Filter Controls -->
  <div class="filter-bar">
    <div class="search-box">
      <span class="search-icon">🔍</span>
      <input type="text" id="filterInput" class="search-input" placeholder="Search by email, user name, medicine name, dosage..." oninput="applyFilter()">
    </div>
    <select id="userDropdownFilter" class="select-filter" onchange="onUserFilterChanged()">
      <option value="all">All Accounts / Users</option>
    </select>
    <select id="statusDropdownFilter" class="select-filter" onchange="applyFilter()">
      <option value="all">All Statuses</option>
      <option value="active">Active Only</option>
      <option value="low_stock">Low Stock (≤ threshold)</option>
    </select>
  </div>

  <!-- Tab 1: Users -->
  <div id="tab-users" class="tab-content">
    <div class="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>User / Account</th>
            <th>Email Address</th>
            <th>Phone Number</th>
            <th>Verification</th>
            <th>Security Setup</th>
            <th>Medicines Added</th>
            <th>Created Date</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody id="tbodyUsers"></tbody>
      </table>
    </div>
  </div>

  <!-- Tab 2: Medicines -->
  <div id="tab-medicines" class="tab-content" style="display:none;">
    <div class="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>Medicine Name & Dosage</th>
            <th>Assigned User / Email</th>
            <th>Type</th>
            <th>Stock & Inventory</th>
            <th>Instruction</th>
            <th>Routine / Schedule</th>
            <th>Course Duration</th>
            <th>Status</th>
            <th>Details</th>
          </tr>
        </thead>
        <tbody id="tbodyMeds"></tbody>
      </table>
    </div>
  </div>

  <!-- Tab 3: Reminders -->
  <div id="tab-reminders" class="tab-content" style="display:none;">
    <div class="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>Scheduled Time</th>
            <th>User / Email</th>
            <th>Medicine</th>
            <th>Repeat Frequency</th>
            <th>Alarm Mode</th>
            <th>Notification ID</th>
          </tr>
        </thead>
        <tbody id="tbodyReminders"></tbody>
      </table>
    </div>
  </div>

  <!-- Tab 4: Intake Logs -->
  <div id="tab-logs" class="tab-content" style="display:none;">
    <div class="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>Scheduled Time</th>
            <th>User / Email</th>
            <th>Medicine</th>
            <th>Dose Status</th>
            <th>Recorded / Taken At</th>
            <th>Cloud Sync Time</th>
          </tr>
        </thead>
        <tbody id="tbodyLogs"></tbody>
      </table>
    </div>
  </div>

  <!-- Tab 5: Security / PIN Requests -->
  <div id="tab-pin" class="tab-content" style="display:none;">
    <div class="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>Requested Date</th>
            <th>User Name</th>
            <th>Email / Phone</th>
            <th>Message</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody id="tbodyPin"></tbody>
      </table>
    </div>
  </div>

  <footer>
    MediRemind Local Cloud Admin Dashboard · Built-in Supabase Sync & Offline Local Cache · Port 8080
  </footer>
</div>

<!-- Medicine Details Modal -->
<div class="modal-overlay" id="detailModal" onclick="closeDetailModal(event)">
  <div class="modal-card" onclick="event.stopPropagation()">
    <div class="modal-header">
      <div class="modal-title" id="modalTitle">Medicine Details</div>
      <button class="modal-close" onclick="closeDetailModal()">&times;</button>
    </div>
    <div class="modal-body" id="modalBody"></div>
  </div>
</div>

<script>
let currentData = null;
let currentTab = 'users';
let selectedUserEmailOrPhone = 'all';

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

function formatTime(hour, minute) {
  if (hour === undefined || minute === undefined) return '—';
  const h = parseInt(hour, 10);
  const m = parseInt(minute, 10);
  const ampm = h >= 12 ? 'PM' : 'AM';
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${String(h12).padStart(2, '0')}:${String(m).padStart(2, '0')} ${ampm}`;
}

function formatDate(isoStr) {
  if (!isoStr) return '—';
  try {
    const d = new Date(isoStr);
    return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
  } catch(e) {
    return isoStr.split('T')[0];
  }
}

function formatDateTime(isoStr) {
  if (!isoStr) return '—';
  try {
    const d = new Date(isoStr);
    return d.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  } catch(e) {
    return isoStr.replace('T', ' ').split('.')[0];
  }
}

function getInstructionLabel(inst) {
  const map = {
    'afterMeal': 'After Meal',
    'beforeMeal': 'Before Meal',
    'withMeal': 'With Meal',
    'emptyStomach': 'Empty Stomach',
    'anytime': 'Any Time'
  };
  return map[inst] || inst || 'After Meal';
}

function switchTab(tabId) {
  currentTab = tabId;
  document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(tc => tc.style.display = 'none');

  const btn = document.getElementById('tabBtn-' + tabId);
  if (btn) btn.classList.add('active');
  const content = document.getElementById('tab-' + tabId);
  if (content) content.style.display = 'block';

  applyFilter();
}

function filterByUser(identifier) {
  selectedUserEmailOrPhone = identifier;
  const select = document.getElementById('userDropdownFilter');
  if (select) select.value = identifier;
  switchTab('medicines');
}

function onUserFilterChanged() {
  const select = document.getElementById('userDropdownFilter');
  selectedUserEmailOrPhone = select.value;
  applyFilter();
}

async function loadData(forceCloud = false) {
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.disabled = true;
    refreshBtn.textContent = '🔄 Syncing...';
  }

  try {
    const url = forceCloud ? '/api/data?refresh=true' : '/api/data';
    const res = await fetch(url);
    const data = await res.json();
    currentData = data;

    // Update connection status
    const badge = document.getElementById('statusBadge');
    const statusText = document.getElementById('statusText');
    const statusSub = document.getElementById('statusSub');

    if (data.data_source === 'supabase_cloud') {
      badge.className = 'status-tag cloud';
      statusText.textContent = 'Supabase Cloud (Live)';
      statusSub.textContent = `Connected to cloud · Last synced at ${data.synced_at || 'just now'}`;
    } else if (data.data_source === 'supabase_cache') {
      badge.className = 'status-tag cached';
      statusText.textContent = 'Offline Cached Data';
      statusSub.textContent = `Displaying cached Supabase data · ${data.synced_at || ''}`;
    } else {
      badge.className = 'status-tag offline';
      statusText.textContent = 'Local SQLite Database';
      statusSub.textContent = data.db_path || 'Local storage';
    }

    if (data.offline_notice) {
      showNotice(data.offline_notice, false);
    }

    // Populate Counts
    const users = data.users || [];
    const meds = data.medicines || [];
    const reminders = data.reminders || [];
    const logs = data.dose_logs || [];
    const pinReqs = data.pin_requests || [];

    document.getElementById('statUsers').textContent = users.length;
    document.getElementById('statMeds').textContent = meds.length;
    document.getElementById('statReminders').textContent = reminders.length;
    document.getElementById('statLogs').textContent = logs.length;

    document.getElementById('badgeUsers').textContent = users.length;
    document.getElementById('badgeMeds').textContent = meds.length;
    document.getElementById('badgeReminders').textContent = reminders.length;
    document.getElementById('badgeLogs').textContent = logs.length;
    document.getElementById('badgePin').textContent = pinReqs.length;

    // Populate User Dropdown filter
    populateUserDropdown(users, meds);

    // Render tables
    renderUsers(users, meds);
    renderMedicines(meds, users);
    renderReminders(reminders, meds);
    renderLogs(logs, meds);
    renderPinRequests(pinReqs);

    applyFilter();
  } catch (err) {
    showNotice('Failed to connect to local server: ' + err.message, true);
  } finally {
    if (refreshBtn) {
      refreshBtn.disabled = false;
      refreshBtn.textContent = '🔄 Sync Cloud (Supabase)';
    }
  }
}

function populateUserDropdown(users, meds) {
  const select = document.getElementById('userDropdownFilter');
  const prevVal = select.value;
  select.innerHTML = '<option value="all">All Accounts / Users</option>';

  // Map users
  const seen = new Set();
  users.forEach(u => {
    const key = u.email || u.phone_number;
    if (key && !seen.has(key)) {
      seen.add(key);
      const opt = document.createElement('option');
      opt.value = key;
      opt.textContent = `${u.name || 'User'} (${key})`;
      select.appendChild(opt);
    }
  });

  // Also include any orphan emails from medicines
  meds.forEach(m => {
    const key = m.email || m.phone_number;
    if (key && !seen.has(key)) {
      seen.add(key);
      const opt = document.createElement('option');
      opt.value = key;
      opt.textContent = `Account (${key})`;
      select.appendChild(opt);
    }
  });

  if (seen.has(prevVal)) {
    select.value = prevVal;
  }
}

function renderUsers(users, meds) {
  const tbody = document.getElementById('tbodyUsers');
  if (!users.length) {
    tbody.innerHTML = '<tr><td colspan="8" class="empty-state"><div class="empty-state-icon">👥</div><div class="empty-state-title">No User Accounts Found</div>No registered accounts found in Supabase.</td></tr>';
    return;
  }

  tbody.innerHTML = users.map(u => {
    const uEmail = u.email || '';
    const uPhone = u.phone_number || '';
    const userMeds = meds.filter(m => (uEmail && m.email === uEmail) || (uPhone && m.phone_number === uPhone));
    const initial = (u.name || uEmail || uPhone || '?').charAt(0).toUpperCase();

    const verifiedBadge = u.is_verified 
      ? '<span class="badge badge-success">✓ Verified</span>' 
      : '<span class="badge badge-warning">Unverified</span>';

    const hasPin = u.security_pin ? '✓ PIN set' : '—';
    const hasSecQ = u.security_question ? '✓ Question set' : '—';
    const secSummary = `${hasPin} · ${hasSecQ}`;

    const identifier = uEmail || uPhone;

    return `<tr>
      <td>
        <div class="user-chip">
          <div class="user-avatar">${escapeHtml(initial)}</div>
          <div class="user-details">
            <span class="user-name">${escapeHtml(u.name || 'Anonymous User')}</span>
            <span class="user-email">${u.is_admin ? '<span class="badge badge-purple" style="font-size:9px; padding:1px 5px;">ADMIN</span>' : 'Standard User'}</span>
          </div>
        </div>
      </td>
      <td>
        ${uEmail ? `<strong>${escapeHtml(uEmail)}</strong>` : '<span style="color:var(--text-subtle)">No email</span>'}
      </td>
      <td>
        ${uPhone ? `<code>${escapeHtml(uPhone)}</code>` : '<span style="color:var(--text-subtle)">No phone</span>'}
      </td>
      <td>${verifiedBadge}</td>
      <td><span style="font-size:12px; color:var(--text-muted);">${escapeHtml(secSummary)}</span></td>
      <td>
        <span class="badge ${userMeds.length > 0 ? 'badge-primary' : 'badge-muted'}">
          ${userMeds.length} medicine${userMeds.length === 1 ? '' : 's'}
        </span>
      </td>
      <td><span style="font-size:12px; color:var(--text-muted);">${formatDate(u.created_at)}</span></td>
      <td>
        <button class="btn btn-secondary btn-sm" onclick="filterByUser('${escapeHtml(identifier)}')">
          💊 View Medicines
        </button>
      </td>
    </tr>`;
  }).join('');
}

function renderMedicines(meds, users) {
  const tbody = document.getElementById('tbodyMeds');
  if (!meds.length) {
    tbody.innerHTML = '<tr><td colspan="9" class="empty-state"><div class="empty-state-icon">💊</div><div class="empty-state-title">No Medicines Found</div>No medicine entries found in database.</td></tr>';
    return;
  }

  tbody.innerHTML = meds.map(m => {
    const userMatch = (users || []).find(u => 
      (m.email && u.email === m.email) || 
      (m.phone_number && u.phone_number === m.phone_number)
    );
    const userName = userMatch ? userMatch.name : (m.email || m.phone_number || 'Local User');
    const userAccount = m.email || m.phone_number || '—';

    const unit = m.unit || (m.type === 'syrup' ? 'ml' : (m.type === 'inhaler' ? 'puffs' : 'tablets'));
    const stock = m.current_stock !== undefined ? m.current_stock : 0;
    const threshold = m.refill_threshold !== undefined ? m.refill_threshold : 5;
    const isLow = stock <= threshold;

    const stockBadge = stock <= 0
      ? `<span class="badge badge-danger">Out of stock (0 ${escapeHtml(unit)})</span>`
      : isLow
        ? `<span class="badge badge-warning">${stock} ${escapeHtml(unit)} (Low)</span>`
        : `<span class="badge badge-success">${stock} ${escapeHtml(unit)}</span>`;

    const statusBadge = m.is_active 
      ? '<span class="badge badge-success">Active</span>'
      : '<span class="badge badge-muted">Paused</span>';

    // Parse reminder slots
    let reminderTimes = [];
    try {
      if (m.reminders_json) {
        const parsed = JSON.parse(m.reminders_json);
        reminderTimes = parsed.map(r => formatTime(r.hour, r.minute));
      }
    } catch(e) {}
    const routineStr = reminderTimes.length > 0 
      ? `⏰ ${reminderTimes.join(', ')}` 
      : '<span style="color:var(--text-subtle)">No reminder slots</span>';

    const courseStr = m.duration_days > 0 
      ? `${m.duration_days} days (${formatDate(m.start_date)})` 
      : 'Ongoing / Chronic';

    return `<tr>
      <td>
        <div style="font-weight:700; color:var(--text-main); font-size:14px;">
          ${escapeHtml(m.name)}
        </div>
        <div style="color:var(--text-muted); font-size:12px;">
          ${escapeHtml(m.dosage || '')} ${escapeHtml(m.unit || '')}
        </div>
      </td>
      <td>
        <div style="font-weight:600; color:var(--primary); font-size:13px;">${escapeHtml(userAccount)}</div>
        <div style="color:var(--text-subtle); font-size:11px;">${escapeHtml(userName)}</div>
      </td>
      <td><span class="badge badge-primary">${escapeHtml(m.type || 'tablet')}</span></td>
      <td>${stockBadge}</td>
      <td><span class="badge badge-purple">${escapeHtml(getInstructionLabel(m.instruction))}</span></td>
      <td><span style="font-size:12px; font-weight:600;">${routineStr}</span></td>
      <td><span style="font-size:12px; color:var(--text-muted);">${courseStr}</span></td>
      <td>${statusBadge}</td>
      <td>
        <button class="btn btn-secondary btn-sm" onclick='showMedicineDetail(${JSON.stringify(m).replace(/'/g, "&#39;")})'>
          Inspect
        </button>
      </td>
    </tr>`;
  }).join('');
}

function renderReminders(reminders, meds) {
  const tbody = document.getElementById('tbodyReminders');
  if (!reminders.length) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty-state"><div class="empty-state-icon">⏰</div><div class="empty-state-title">No Reminders Found</div>No reminder schedules found.</td></tr>';
    return;
  }

  tbody.innerHTML = reminders.map(r => {
    const med = (meds || []).find(m => m.id === r.medicine_id);
    const medName = med ? `${med.name} (${med.dosage || ''})` : (r.medicine_id ? r.medicine_id.substring(0, 8) + '...' : 'Unknown');
    const timeDisplay = formatTime(r.hour, r.minute);
    const alarmBadge = r.is_alarm 
      ? '<span class="badge badge-success">Full Alarm</span>'
      : '<span class="badge badge-muted">Notification</span>';

    const account = r.email || r.phone_number || (med ? (med.email || med.phone_number) : '—');

    return `<tr>
      <td><strong style="font-size:15px; color:var(--primary);">${timeDisplay}</strong></td>
      <td><code>${escapeHtml(account)}</code></td>
      <td><strong>${escapeHtml(medName)}</strong></td>
      <td>${formatDays(r.days_of_week)}</td>
      <td>${alarmBadge}</td>
      <td><code style="font-size:11px; color:var(--text-subtle);">${r.notification_id || '—'}</code></td>
    </tr>`;
  }).join('');
}

function renderLogs(logs, meds) {
  const tbody = document.getElementById('tbodyLogs');
  if (!logs.length) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty-state"><div class="empty-state-icon">📋</div><div class="empty-state-title">No Intake Logs</div>No doses have been recorded yet.</td></tr>';
    return;
  }

  tbody.innerHTML = logs.map(l => {
    const med = (meds || []).find(m => m.id === l.medicine_id);
    const medName = med ? med.name : (l.medicine_id ? l.medicine_id.substring(0, 8) + '...' : '—');
    const statusClass = l.status === 'taken' ? 'badge-success' : (l.status === 'skipped' ? 'badge-danger' : 'badge-warning');
    const account = l.email || l.phone_number || (med ? (med.email || med.phone_number) : '—');

    return `<tr>
      <td><strong>${formatDateTime(l.scheduled_time)}</strong></td>
      <td><code>${escapeHtml(account)}</code></td>
      <td><strong>${escapeHtml(medName)}</strong></td>
      <td><span class="badge ${statusClass}">${escapeHtml(l.status || 'unknown')}</span></td>
      <td style="color:var(--text-muted); font-size:12px;">${formatDateTime(l.taken_at)}</td>
      <td style="color:var(--text-subtle); font-size:11px;">${formatDateTime(l.synced_at)}</td>
    </tr>`;
  }).join('');
}

function renderPinRequests(reqs) {
  const tbody = document.getElementById('tbodyPin');
  if (!reqs.length) {
    tbody.innerHTML = '<tr><td colspan="5" class="empty-state"><div class="empty-state-icon">🔐</div><div class="empty-state-title">No PIN Reset Requests</div>No pending security requests found.</td></tr>';
    return;
  }

  tbody.innerHTML = reqs.map(p => `<tr>
    <td>${formatDateTime(p.created_at)}</td>
    <td><strong>${escapeHtml(p.user_name || 'User')}</strong></td>
    <td><code>${escapeHtml(p.email || p.phone_number || '—')}</code></td>
    <td>${escapeHtml(p.message || '—')}</td>
    <td><span class="badge badge-warning">${escapeHtml(p.status || 'pending')}</span></td>
  </tr>`).join('');
}

function applyFilter() {
  if (!currentData) return;
  const query = (document.getElementById('filterInput').value || '').toLowerCase().trim();
  const selectedUser = selectedUserEmailOrPhone;
  const statusFilter = document.getElementById('statusDropdownFilter').value;

  const users = currentData.users || [];
  const meds = currentData.medicines || [];
  const reminders = currentData.reminders || [];
  const logs = currentData.dose_logs || [];

  if (currentTab === 'users') {
    const filtered = users.filter(u => 
      (!query || 
        (u.name || '').toLowerCase().includes(query) ||
        (u.email || '').toLowerCase().includes(query) ||
        (u.phone_number || '').toLowerCase().includes(query)
      ) &&
      (selectedUser === 'all' || u.email === selectedUser || u.phone_number === selectedUser)
    );
    renderUsers(filtered, meds);
  } else if (currentTab === 'medicines') {
    const filtered = meds.filter(m => {
      const matchUser = selectedUser === 'all' || m.email === selectedUser || m.phone_number === selectedUser;
      const matchQuery = !query || 
        (m.name || '').toLowerCase().includes(query) ||
        (m.dosage || '').toLowerCase().includes(query) ||
        (m.email || '').toLowerCase().includes(query) ||
        (m.type || '').toLowerCase().includes(query);
      
      let matchStatus = true;
      if (statusFilter === 'active') matchStatus = m.is_active;
      if (statusFilter === 'low_stock') matchStatus = (m.current_stock || 0) <= (m.refill_threshold || 5);

      return matchUser && matchQuery && matchStatus;
    });
    renderMedicines(filtered, users);
  } else if (currentTab === 'reminders') {
    const filtered = reminders.filter(r => {
      const matchUser = selectedUser === 'all' || r.email === selectedUser || r.phone_number === selectedUser;
      const matchQuery = !query || (r.email || '').toLowerCase().includes(query);
      return matchUser && matchQuery;
    });
    renderReminders(filtered, meds);
  } else if (currentTab === 'logs') {
    const filtered = logs.filter(l => {
      const matchUser = selectedUser === 'all' || l.email === selectedUser || l.phone_number === selectedUser;
      const matchQuery = !query || (l.email || '').toLowerCase().includes(query) || (l.status || '').toLowerCase().includes(query);
      return matchUser && matchQuery;
    });
    renderLogs(filtered, meds);
  }
}

function showMedicineDetail(m) {
  document.getElementById('modalTitle').textContent = `${m.name} - Full Details`;
  const body = document.getElementById('modalBody');

  body.innerHTML = `
    <div class="detail-row"><span class="detail-label">Medicine ID</span><span class="detail-val"><code>${escapeHtml(m.id)}</code></span></div>
    <div class="detail-row"><span class="detail-label">Name</span><span class="detail-val"><strong>${escapeHtml(m.name)}</strong></span></div>
    <div class="detail-row"><span class="detail-label">Dosage</span><span class="detail-val">${escapeHtml(m.dosage || '—')} ${escapeHtml(m.unit || '')}</span></div>
    <div class="detail-row"><span class="detail-label">Type</span><span class="detail-val"><span class="badge badge-primary">${escapeHtml(m.type || 'tablet')}</span></span></div>
    <div class="detail-row"><span class="detail-label">User Email</span><span class="detail-val"><code>${escapeHtml(m.email || '—')}</code></span></div>
    <div class="detail-row"><span class="detail-label">User Phone</span><span class="detail-val"><code>${escapeHtml(m.phone_number || '—')}</code></span></div>
    <div class="detail-row"><span class="detail-label">Current Stock</span><span class="detail-val">${m.current_stock || 0} ${escapeHtml(m.unit || '')} (Refill alert at ≤ ${m.refill_threshold || 5})</span></div>
    <div class="detail-row"><span class="detail-label">Instruction</span><span class="detail-val">${escapeHtml(getInstructionLabel(m.instruction))}</span></div>
    <div class="detail-row"><span class="detail-label">Course Duration</span><span class="detail-val">${m.duration_days > 0 ? m.duration_days + ' days' : 'Ongoing'}</span></div>
    <div class="detail-row"><span class="detail-label">Start Date</span><span class="detail-val">${formatDateTime(m.start_date)}</span></div>
    <div class="detail-row"><span class="detail-label">End Date</span><span class="detail-val">${formatDateTime(m.end_date)}</span></div>
    <div class="detail-row"><span class="detail-label">Reminders Schedule</span><span class="detail-val"><pre style="font-size:11px; text-align:left; background:var(--bg-inner); padding:8px; border-radius:6px; overflow-x:auto;">${escapeHtml(m.reminders_json || '[]')}</pre></span></div>
    <div class="detail-row"><span class="detail-label">Notes</span><span class="detail-val">${escapeHtml(m.notes || '—')}</span></div>
    <div class="detail-row"><span class="detail-label">Status</span><span class="detail-val">${m.is_active ? '<span class="badge badge-success">Active</span>' : '<span class="badge badge-muted">Paused</span>'}</span></div>
  `;

  document.getElementById('detailModal').style.display = 'flex';
}

function closeDetailModal(e) {
  document.getElementById('detailModal').style.display = 'none';
}

async function syncFromADB() {
  const btn = document.getElementById('syncAdbBtn');
  btn.disabled = true;
  btn.textContent = '📱 Checking phone...';

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
    btn.textContent = '📱 Sync ADB';
  }
}

function exportJSON() {
  if (!currentData) return;
  const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(currentData, null, 2));
  const downloadAnchor = document.createElement('a');
  downloadAnchor.setAttribute("href", dataStr);
  downloadAnchor.setAttribute("download", `mediremind_export_${new Date().toISOString().split('T')[0]}.json`);
  document.body.appendChild(downloadAnchor);
  downloadAnchor.click();
  downloadAnchor.remove();
}

function showNotice(msg, isError = false) {
  const b = document.getElementById('bannerMsg');
  b.style.display = 'flex';
  b.style.background = isError ? 'rgba(239, 68, 68, 0.15)' : 'rgba(16, 185, 129, 0.15)';
  b.style.borderColor = isError ? '#EF4444' : '#10B981';
  b.style.color = isError ? '#F87171' : '#34D399';
  b.innerHTML = `<span>${escapeHtml(msg)}</span><button onclick="document.getElementById('bannerMsg').style.display='none'" style="background:none; border:none; color:inherit; cursor:pointer; font-weight:bold; font-size:16px;">&times;</button>`;
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

window.onload = () => loadData();
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
        query = parse_qs(parsed.query)

        if path == "/" or path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
        elif path == "/api/data":
            force_cloud = "refresh" in query
            data = get_combined_data(getattr(self.server, "custom_db_path", None), force_cloud=force_cloud)
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
            target_path = get_db_path(getattr(self.server, "custom_db_path", None))
            success, msg = pull_database_from_adb(target_path)
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps({"success": success, "message": msg}, ensure_ascii=False).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

def main():
    parser = argparse.ArgumentParser(description="MediRemind Local & Cloud Admin Dashboard")
    parser.add_argument("--port", type=int, default=8080, help="Port to run web server on (default: 8080)")
    parser.add_argument("--db", type=str, default=None, help="Path to local mediremind.db SQLite file")
    parser.add_argument("--no-browser", action="store_true", help="Do not automatically open browser")
    parser.add_argument("--test", action="store_true", help="Run self-test and exit immediately")
    args = parser.parse_args()

    if args.test:
        print("[TEST] Fetching data...")
        data = get_combined_data(args.db)
        print(f"[TEST] Source: {data.get('data_source')}, Status: {data.get('status')}")
        print(f"[TEST] Users: {len(data.get('users', []))}, Medicines: {len(data.get('medicines', []))}")
        return

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

    # Initial data prefetch
    print("Connecting to Supabase Cloud & inspecting databases...")
    initial_data = get_combined_data(args.db)
    u_count = len(initial_data.get("users", []))
    m_count = len(initial_data.get("medicines", []))
    r_count = len(initial_data.get("reminders", []))
    source = initial_data.get("data_source", "unknown")

    print("=" * 68)
    print("  💊 MediRemind - Cloud & Offline Admin Dashboard")
    print(f"  🌐 Portal Web URL: {url}")
    print(f"  ☁️  Data Source:    {source.upper()}")
    print(f"  👥 Registered Users: {u_count}")
    print(f"  💊 Total Medicines:  {m_count}")
    print(f"  ⏰ Active Reminders: {r_count}")
    print("=" * 68)
    print("Opening browser... (Press Ctrl+C to stop server)\n")

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
