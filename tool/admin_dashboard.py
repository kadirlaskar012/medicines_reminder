#!/usr/bin/env python3
"""
MediRemind - Offline & Cloud Admin Dashboard
============================================
A lightweight, zero-dependency, ultra-fast admin portal to inspect, search,
and manage MediRemind user accounts directly in your browser.

Features:
- Clean, focused user list with checkbox (tick) multi-select.
- One-click or bulk user deletion from Supabase Cloud and local cache.
- Rich, interactive popup modal with complete user details (medicines, reminders, logs, security).
- 100% responsive, zero external dependencies (pure Python standard library).

Usage:
    python tool/admin_dashboard.py [--port 8080] [--no-browser]
"""

import http.server
import socketserver
import json
import os
import sys
import webbrowser
import subprocess
import argparse
import datetime
import urllib.parse
from urllib.parse import parse_qs, urlparse
import urllib.request
import urllib.error

# Project paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CACHE_FILE = os.path.join(SCRIPT_DIR, "mediremind_cache.json")

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
    """Fetch all relevant tables from Supabase Cloud and update local cache."""
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

    users, err = fetch_supabase_table("app_users")
    if err and users is None:
        data["status"] = "error"
        data["error"] = f"Supabase connection failed: {err}"
        return data
    data["users"] = users or []

    meds, _ = fetch_supabase_table("user_medicines")
    data["medicines"] = meds or []

    reminders, _ = fetch_supabase_table("user_reminders")
    data["reminders"] = reminders or []

    logs, _ = fetch_supabase_table("user_dose_logs")
    data["dose_logs"] = logs or []

    pin_reqs, _ = fetch_supabase_table("pin_reset_requests")
    data["pin_requests"] = pin_reqs or []

    # Cache locally so offline mode functions seamlessly
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

def delete_single_user(user_id=None, email=None, phone=None):
    """Delete single user and cascade their medicines, reminders, dose logs from Supabase."""
    filters = []
    if email and str(email).strip():
        filters.append(("email", str(email).strip().lower()))
    if phone and str(phone).strip():
        filters.append(("phone_number", str(phone).strip()))

    child_tables = ["user_reminders", "user_dose_logs", "user_medicines", "pin_reset_requests"]

    # 1. Delete child records
    for col, val in filters:
        quoted = urllib.parse.quote(val)
        for tbl in child_tables:
            try:
                url = f"{SUPABASE_URL}/rest/v1/{tbl}?{col}=eq.{quoted}"
                req = urllib.request.Request(
                    url,
                    headers={
                        "apikey": SUPABASE_ANON_KEY,
                        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
                        "Prefer": "return=representation"
                    },
                    method="DELETE"
                )
                with urllib.request.urlopen(req, timeout=10) as resp:
                    pass
            except Exception as e:
                print(f"[WARN] Error deleting from {tbl} where {col}={val}: {e}")

    # 2. Delete from app_users
    if user_id and str(user_id).strip():
        try:
            url = f"{SUPABASE_URL}/rest/v1/app_users?id=eq.{urllib.parse.quote(str(user_id).strip())}"
            req = urllib.request.Request(
                url,
                headers={
                    "apikey": SUPABASE_ANON_KEY,
                    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
                    "Prefer": "return=representation"
                },
                method="DELETE"
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                pass
        except Exception as e:
            print(f"[WARN] Error deleting from app_users by id: {e}")

    for col, val in filters:
        try:
            url = f"{SUPABASE_URL}/rest/v1/app_users?{col}=eq.{urllib.parse.quote(val)}"
            req = urllib.request.Request(
                url,
                headers={
                    "apikey": SUPABASE_ANON_KEY,
                    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
                    "Prefer": "return=representation"
                },
                method="DELETE"
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                pass
        except Exception as e:
            print(f"[WARN] Error deleting from app_users by {col}: {e}")

def delete_users_from_supabase(user_list):
    """
    Delete multiple or single user(s) and their associated records.
    user_list: list of dicts with keys userId, email, phone.
    """
    if not isinstance(user_list, list):
        user_list = [user_list]

    for u in user_list:
        delete_single_user(
            user_id=u.get("userId") or u.get("id"),
            email=u.get("email"),
            phone=u.get("phone") or u.get("phone_number")
        )

    # Re-fetch data and refresh cache
    fetch_all_supabase_data()
    return True, f"{len(user_list)} user(s) and their cloud data were permanently deleted."

def get_combined_data(force_cloud=False):
    """Fetch live from Supabase, or fall back to cached snapshot."""
    cloud_data = fetch_all_supabase_data()
    if cloud_data.get("status") == "ok":
        return cloud_data

    cached = load_cached_data()
    if cached:
        cached["offline_notice"] = "Displaying offline cached data (Supabase Cloud is currently unreachable)."
        return cached

    return cloud_data

HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MediRemind Admin - User Management</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --bg-main: #0B1120;
    --bg-card: #151F32;
    --bg-card-hover: #1E2B45;
    --bg-inner: #0E1726;
    --border: #24344D;
    --border-light: #334968;
    --text-main: #F8FAFC;
    --text-muted: #94A3B8;
    --text-subtle: #64748B;
    --primary: #0EA5E9;
    --primary-glow: rgba(14, 165, 233, 0.25);
    --primary-hover: #0284C7;
    --accent: #10B981;
    --warning: #F59E0B;
    --danger: #EF4444;
    --danger-hover: #DC2626;
    --danger-glow: rgba(239, 68, 68, 0.25);
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
  .container { max-width: 1280px; margin: 0 auto; }

  /* Header */
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
  .brand { display: flex; align-items: center; gap: 14px; }
  .logo-icon {
    width: 46px; height: 46px;
    background: linear-gradient(135deg, #0EA5E9 0%, #10B981 100%);
    border-radius: 14px;
    display: flex; align-items: center; justify-content: center;
    font-size: 24px;
    box-shadow: 0 4px 18px var(--primary-glow);
  }
  h1 { font-size: 22px; font-weight: 800; letter-spacing: -0.5px; }
  .status-tag {
    display: inline-flex; align-items: center; gap: 6px;
    font-size: 12px; font-weight: 600; padding: 2px 10px;
    border-radius: 20px; margin-top: 4px;
  }
  .status-tag.cloud { background: rgba(16, 185, 129, 0.15); color: #34D399; border: 1px solid rgba(16, 185, 129, 0.3); }
  .status-tag.cached { background: rgba(245, 158, 11, 0.15); color: #FBBF24; border: 1px solid rgba(245, 158, 11, 0.3); }
  .status-dot { width: 7px; height: 7px; border-radius: 50%; background: currentColor; animation: pulse 2s infinite; }
  @keyframes pulse { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(0.8); } }

  .header-actions { display: flex; gap: 10px; align-items: center; }
  .btn {
    padding: 9px 16px;
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
  .btn-danger {
    background: rgba(239, 68, 68, 0.18);
    color: #F87171;
    border: 1px solid rgba(239, 68, 68, 0.35);
  }
  .btn-danger:hover {
    background: var(--danger-hover);
    color: white;
    box-shadow: 0 4px 14px var(--danger-glow);
  }
  .btn-sm { padding: 6px 12px; font-size: 12px; border-radius: 8px; }

  /* Notification Banner */
  .notice-banner {
    border-radius: 12px;
    padding: 12px 18px;
    font-size: 13px;
    margin-bottom: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
  }

  /* Stats summary pills */
  .stats-bar {
    display: flex;
    gap: 12px;
    margin-bottom: 20px;
    flex-wrap: wrap;
  }
  .stat-pill {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 10px 18px;
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 13px;
  }
  .stat-pill-val { font-size: 18px; font-weight: 800; color: var(--primary); }
  .stat-pill-label { color: var(--text-muted); font-weight: 500; }

  /* Selection Toolbar (shows when rows are ticked) */
  .selection-bar {
    background: linear-gradient(90deg, rgba(239, 68, 68, 0.12), rgba(15, 23, 42, 0.8));
    border: 1px solid rgba(239, 68, 68, 0.35);
    border-radius: 14px;
    padding: 12px 20px;
    margin-bottom: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
    animation: fadeIn 0.2s ease;
  }
  @keyframes fadeIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
  .selection-info { font-weight: 700; color: #FCA5A5; display: flex; align-items: center; gap: 8px; font-size: 14px; }
  .selection-actions { display: flex; gap: 10px; align-items: center; }

  /* Search Bar */
  .search-wrapper {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 14px;
    margin-bottom: 16px;
    flex-wrap: wrap;
  }
  .search-box {
    flex: 1;
    min-width: 280px;
    position: relative;
  }
  .search-input {
    width: 100%;
    padding: 12px 16px 12px 42px;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 12px;
    color: var(--text-main);
    font-size: 13px;
    outline: none;
    font-family: inherit;
    transition: all 0.2s;
  }
  .search-input:focus { border-color: var(--primary); box-shadow: 0 0 0 3px var(--primary-glow); }
  .search-icon {
    position: absolute; left: 14px; top: 50%; transform: translateY(-50%);
    color: var(--text-subtle); font-size: 15px; pointer-events: none;
  }
  .user-count-badge { font-size: 12px; color: var(--text-muted); font-weight: 600; }

  /* Table styling */
  .table-wrapper {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.3);
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
    user-select: none;
  }
  td {
    padding: 14px 18px;
    border-bottom: 1px solid rgba(36, 52, 77, 0.6);
    vertical-align: middle;
  }
  tr.clickable-row {
    cursor: pointer;
    transition: background 0.15s;
  }
  tr.clickable-row:hover {
    background: var(--bg-card-hover);
  }
  tr.selected-row {
    background: rgba(14, 165, 233, 0.08) !important;
  }
  tr:last-child td { border-bottom: none; }

  /* Checkbox styling */
  .checkbox-custom {
    width: 18px; height: 18px;
    accent-color: var(--primary);
    cursor: pointer;
    transform: scale(1.15);
  }

  /* User chip */
  .user-chip {
    display: inline-flex;
    align-items: center;
    gap: 10px;
  }
  .user-avatar {
    width: 36px; height: 36px;
    border-radius: 10px;
    background: linear-gradient(135deg, #0EA5E9, #8B5CF6);
    display: flex; align-items: center; justify-content: center;
    font-weight: 800; font-size: 14px; color: white;
    flex-shrink: 0;
  }
  .user-details { display: flex; flex-direction: column; }
  .user-name { font-weight: 700; color: var(--text-main); font-size: 14px; }
  .user-email-sub { font-size: 11px; color: var(--text-muted); }

  /* Badges */
  .badge {
    display: inline-flex; align-items: center; gap: 4px;
    padding: 3px 9px;
    border-radius: 7px;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }
  .badge-success { background: rgba(16, 185, 129, 0.15); color: #34D399; border: 1px solid rgba(16, 185, 129, 0.3); }
  .badge-warning { background: rgba(245, 158, 11, 0.15); color: #FBBF24; border: 1px solid rgba(245, 158, 11, 0.3); }
  .badge-primary { background: rgba(14, 165, 233, 0.15); color: #38BDF8; border: 1px solid rgba(14, 165, 233, 0.3); }
  .badge-purple { background: rgba(139, 92, 246, 0.15); color: #C4B5FD; border: 1px solid rgba(139, 92, 246, 0.3); }
  .badge-muted { background: rgba(100, 116, 139, 0.15); color: #94A3B8; border: 1px solid rgba(100, 116, 139, 0.3); }

  /* Action buttons */
  .action-icon-btn {
    background: transparent;
    border: none;
    cursor: pointer;
    font-size: 16px;
    padding: 6px;
    border-radius: 8px;
    color: var(--text-muted);
    transition: all 0.2s;
  }
  .action-icon-btn:hover { background: rgba(239, 68, 68, 0.2); color: #EF4444; }

  /* Empty state */
  .empty-state {
    text-align: center;
    padding: 56px 20px;
    color: var(--text-muted);
  }
  .empty-icon { font-size: 44px; margin-bottom: 10px; opacity: 0.7; }
  .empty-title { font-size: 15px; font-weight: 700; color: var(--text-main); margin-bottom: 4px; }

  /* Modal Popup */
  .modal-overlay {
    position: fixed; inset: 0; background: rgba(0, 0, 0, 0.8);
    backdrop-filter: blur(6px); display: none; align-items: center; justify-content: center;
    z-index: 2000; padding: 20px;
  }
  .modal-card {
    background: var(--bg-card);
    border: 1px solid var(--border-light);
    border-radius: 20px;
    max-width: 780px; width: 100%;
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.7);
    display: flex; flex-direction: column;
    max-height: 85vh;
    animation: modalSlide 0.2s ease;
  }
  @keyframes modalSlide { from { opacity: 0; transform: scale(0.97) translateY(10px); } to { opacity: 1; transform: scale(1) translateY(0); } }
  .modal-header {
    padding: 20px 24px;
    border-bottom: 1px solid var(--border);
    display: flex; justify-content: space-between; align-items: center;
    background: var(--bg-inner);
    border-radius: 20px 20px 0 0;
  }
  .modal-header-profile {
    display: flex; align-items: center; gap: 14px;
  }
  .modal-avatar {
    width: 48px; height: 48px;
    border-radius: 14px;
    background: linear-gradient(135deg, #0EA5E9, #8B5CF6);
    display: flex; align-items: center; justify-content: center;
    font-weight: 800; font-size: 20px; color: white;
  }
  .modal-title { font-size: 18px; font-weight: 800; color: var(--text-main); }
  .modal-subtitle { font-size: 12px; color: var(--primary); font-weight: 600; }
  .modal-close-btn {
    background: transparent; border: none; color: var(--text-muted);
    font-size: 24px; cursor: pointer; padding: 4px 8px; border-radius: 8px;
  }
  .modal-close-btn:hover { color: var(--text-main); background: var(--border); }
  
  .modal-body {
    padding: 24px;
    overflow-y: auto;
    flex: 1;
  }
  .modal-section-title {
    font-size: 12px; font-weight: 800; text-transform: uppercase;
    letter-spacing: 0.8px; color: var(--text-subtle); margin-bottom: 12px;
    display: flex; align-items: center; gap: 8px;
  }
  .detail-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 12px;
    margin-bottom: 24px;
  }
  .detail-box {
    background: var(--bg-inner);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 12px 16px;
  }
  .detail-box-label { font-size: 11px; font-weight: 600; color: var(--text-muted); margin-bottom: 4px; }
  .detail-box-val { font-size: 13px; font-weight: 700; color: var(--text-main); word-break: break-word; }

  /* Medicine items inside modal */
  .med-item-card {
    background: var(--bg-inner);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 14px 18px;
    margin-bottom: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
  }
  .med-item-card:hover { border-color: var(--primary); }
  .med-title { font-size: 15px; font-weight: 700; color: var(--text-main); }
  .med-meta { font-size: 12px; color: var(--text-muted); margin-top: 2px; }

  .modal-footer {
    padding: 16px 24px;
    border-top: 1px solid var(--border);
    display: flex; justify-content: space-between; align-items: center;
    background: var(--bg-inner);
    border-radius: 0 0 20px 20px;
  }

  footer {
    margin-top: 36px;
    text-align: center;
    font-size: 12px;
    color: var(--text-subtle);
    border-top: 1px solid var(--border);
    padding-top: 20px;
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
          <h1>MediRemind Users Admin</h1>
          <span class="status-tag cloud" id="statusBadge">
            <span class="status-dot"></span> <span id="statusText">Connecting...</span>
          </span>
        </div>
        <div style="font-size: 12px; color: var(--text-muted); margin-top: 3px;" id="statusSub">
          Click any user to view full profile & medicines. Check the box to delete.
        </div>
      </div>
    </div>
    <div class="header-actions">
      <button class="btn btn-secondary" onclick="exportJSON()">📥 Export JSON</button>
      <button class="btn btn-primary" onclick="loadData(true)" id="refreshBtn">🔄 Sync Cloud (Supabase)</button>
    </div>
  </header>

  <!-- Notice Banner -->
  <div class="notice-banner" id="bannerMsg" style="display:none;"></div>

  <!-- Summary Statistics Bar -->
  <div class="stats-bar">
    <div class="stat-pill">
      <span class="stat-pill-val" id="statUsers">0</span>
      <span class="stat-pill-label">Registered Users</span>
    </div>
    <div class="stat-pill">
      <span class="stat-pill-val" id="statMeds">0</span>
      <span class="stat-pill-label">Total Medicines</span>
    </div>
    <div class="stat-pill">
      <span class="stat-pill-val" id="statReminders">0</span>
      <span class="stat-pill-label">Active Reminders</span>
    </div>
    <div class="stat-pill">
      <span class="stat-pill-val" id="statLogs">0</span>
      <span class="stat-pill-label">Dose Logs Recorded</span>
    </div>
  </div>

  <!-- Selection Action Bar (Shown when users are ticked) -->
  <div class="selection-bar" id="selectionBar" style="display:none;">
    <div class="selection-info">
      <span>☑️</span>
      <span id="selectionCountText">0 users selected</span>
    </div>
    <div class="selection-actions">
      <button class="btn btn-secondary btn-sm" onclick="clearAllSelections()">✕ Cancel</button>
      <button class="btn btn-danger" onclick="deleteSelectedUsers()">🗑️ Delete Selected Users</button>
    </div>
  </div>

  <!-- Search & User Count -->
  <div class="search-wrapper">
    <div class="search-box">
      <span class="search-icon">🔍</span>
      <input type="text" id="searchInput" class="search-input" placeholder="Search users by name, email, phone number, or medicines..." oninput="applyFilter()">
    </div>
    <div class="user-count-badge" id="displayCountText">Showing 0 users</div>
  </div>

  <!-- Main Users Table -->
  <div class="table-wrapper">
    <table>
      <thead>
        <tr>
          <th style="width: 44px; text-align: center;">
            <input type="checkbox" id="selectAllCheckbox" class="checkbox-custom" title="Select All Users" onchange="toggleSelectAll(this)">
          </th>
          <th>User Account</th>
          <th>Email Address</th>
          <th>Phone Number</th>
          <th>Status</th>
          <th>Medicines Added</th>
          <th>Registered Date</th>
          <th style="text-align: right;">Action</th>
        </tr>
      </thead>
      <tbody id="tbodyUsers"></tbody>
    </table>
  </div>

  <footer>
    MediRemind Admin Panel · Ultra-Fast Local Engine · Connected to Supabase Cloud
  </footer>
</div>

<!-- Detailed User Profile Modal -->
<div class="modal-overlay" id="userModal" onclick="closeUserModal(event)">
  <div class="modal-card" onclick="event.stopPropagation()">
    <div class="modal-header">
      <div class="modal-header-profile">
        <div class="modal-avatar" id="mAvatar">?</div>
        <div>
          <div class="modal-title" id="mName">User Name</div>
          <div class="modal-subtitle" id="mEmailOrPhone">email@example.com</div>
        </div>
      </div>
      <button class="modal-close-btn" onclick="closeUserModal()">&times;</button>
    </div>
    
    <div class="modal-body">
      <!-- Section 1: User Profile & Security Details -->
      <div class="modal-section-title">👤 Account & Security Details</div>
      <div class="detail-grid">
        <div class="detail-box">
          <div class="detail-box-label">User ID (UUID)</div>
          <div class="detail-box-val"><code id="mUserId" style="font-size:11px;">—</code></div>
        </div>
        <div class="detail-box">
          <div class="detail-box-label">Account Role</div>
          <div class="detail-box-val" id="mRole">—</div>
        </div>
        <div class="detail-box">
          <div class="detail-box-label">Verification Status</div>
          <div class="detail-box-val" id="mVerified">—</div>
        </div>
        <div class="detail-box">
          <div class="detail-box-label">Registered / Created At</div>
          <div class="detail-box-val" id="mCreatedAt">—</div>
        </div>
        <div class="detail-box">
          <div class="detail-box-label">Last Login</div>
          <div class="detail-box-val" id="mLastLogin">—</div>
        </div>
        <div class="detail-box">
          <div class="detail-box-label">Password / PIN Status</div>
          <div class="detail-box-val" id="mPinStatus">—</div>
        </div>
        <div class="detail-box" style="grid-column: 1 / -1;">
          <div class="detail-box-label">Security Question & Answer</div>
          <div class="detail-box-val" id="mSecQA">—</div>
        </div>
      </div>

      <!-- Section 2: Medicines Added -->
      <div class="modal-section-title" id="mMedsHeader">💊 Medicines Added (0)</div>
      <div id="mMedsList"></div>

      <!-- Section 3: Reminder Schedules -->
      <div class="modal-section-title" id="mRemindersHeader" style="margin-top:20px;">⏰ Routine & Reminder Alarms (0)</div>
      <div id="mRemindersList"></div>

      <!-- Section 4: Dose Logs -->
      <div class="modal-section-title" id="mLogsHeader" style="margin-top:20px;">📋 Dose Intake History (0)</div>
      <div id="mLogsList"></div>
    </div>

    <div class="modal-footer">
      <button class="btn btn-danger" id="mDeleteUserBtn" onclick="deleteUserFromModal()">
        🗑️ Delete This User
      </button>
      <button class="btn btn-secondary" onclick="closeUserModal()">Close</button>
    </div>
  </div>
</div>

<script>
let currentData = null;
let selectedUserKeys = new Set();
let activeModalUser = null;

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

function formatDateTime(isoStr) {
  if (!isoStr) return '—';
  try {
    const d = new Date(isoStr);
    return d.toLocaleString(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  } catch(e) {
    return isoStr.replace('T', ' ').split('.')[0];
  }
}

function getInstructionLabel(inst) {
  const map = {
    'afterMeal': 'After Meal (খাওয়ার পর)',
    'beforeMeal': 'Before Meal (খাওয়ার আগে)',
    'withMeal': 'With Meal (খাওয়ার সাথে)',
    'emptyStomach': 'Empty Stomach (খালি পেটে)',
    'anytime': 'Any Time'
  };
  return map[inst] || inst || 'After Meal';
}

async function loadData(forceCloud = false) {
  const btn = document.getElementById('refreshBtn');
  if (btn) {
    btn.disabled = true;
    btn.textContent = '🔄 Syncing...';
  }

  try {
    const url = forceCloud ? '/api/data?refresh=true' : '/api/data';
    const res = await fetch(url);
    const data = await res.json();
    currentData = data;

    const badge = document.getElementById('statusBadge');
    const statusText = document.getElementById('statusText');
    const statusSub = document.getElementById('statusSub');

    if (data.data_source === 'supabase_cloud') {
      badge.className = 'status-tag cloud';
      statusText.textContent = 'Supabase Cloud (Live)';
      statusSub.textContent = `Live Cloud Sync · Synced at ${data.synced_at || 'just now'}`;
    } else {
      badge.className = 'status-tag cached';
      statusText.textContent = 'Offline Cached Mode';
      statusSub.textContent = `Displaying saved cache (${data.synced_at || ''})`;
    }

    if (data.offline_notice) {
      showNotice(data.offline_notice, false);
    }

    // Counts
    const users = data.users || [];
    const meds = data.medicines || [];
    const reminders = data.reminders || [];
    const logs = data.dose_logs || [];

    document.getElementById('statUsers').textContent = users.length;
    document.getElementById('statMeds').textContent = meds.length;
    document.getElementById('statReminders').textContent = reminders.length;
    document.getElementById('statLogs').textContent = logs.length;

    // Clear stale selections
    selectedUserKeys.clear();
    updateSelectionBar();

    renderUsersTable(users, meds);
  } catch (err) {
    showNotice('Failed to fetch data: ' + err.message, true);
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.textContent = '🔄 Sync Cloud (Supabase)';
    }
  }
}

function getUserIdentifier(u) {
  return u.email || u.phone_number || u.id;
}

function getUserMedicines(u, meds) {
  const uEmail = (u.email || '').toLowerCase().trim();
  const uPhone = (u.phone_number || '').trim();
  return (meds || []).filter(m => 
    (uEmail && (m.email || '').toLowerCase().trim() === uEmail) ||
    (uPhone && (m.phone_number || '').trim() === uPhone)
  );
}

function renderUsersTable(users, meds) {
  const tbody = document.getElementById('tbodyUsers');
  document.getElementById('displayCountText').textContent = `Showing ${users.length} users`;

  if (!users.length) {
    tbody.innerHTML = `<tr>
      <td colspan="8" class="empty-state">
        <div class="empty-icon">👥</div>
        <div class="empty-title">No Users Found</div>
        <div>No registered users found in Supabase.</div>
      </td>
    </tr>`;
    return;
  }

  tbody.innerHTML = users.map(u => {
    const key = getUserIdentifier(u);
    const isChecked = selectedUserKeys.has(key);
    const uEmail = u.email || '';
    const uPhone = u.phone_number || '';
    const userMeds = getUserMedicines(u, meds);
    const initial = (u.name || uEmail || uPhone || '?').charAt(0).toUpperCase();

    const verifiedBadge = u.is_verified
      ? '<span class="badge badge-success">✓ Verified</span>'
      : '<span class="badge badge-warning">Unverified</span>';

    return `<tr class="clickable-row ${isChecked ? 'selected-row' : ''}" onclick="onRowClick(event, '${escapeHtml(key)}')">
      <td style="text-align:center;" onclick="event.stopPropagation()">
        <input type="checkbox" class="checkbox-custom row-checkbox" 
          value="${escapeHtml(key)}" 
          ${isChecked ? 'checked' : ''} 
          onchange="toggleUserSelect('${escapeHtml(key)}', this.checked)">
      </td>
      <td>
        <div class="user-chip">
          <div class="user-avatar">${escapeHtml(initial)}</div>
          <div class="user-details">
            <span class="user-name">${escapeHtml(u.name || 'Anonymous')}</span>
            <span class="user-email-sub">${u.is_admin ? '<span class="badge badge-purple" style="font-size:9px; padding:1px 5px;">ADMIN</span>' : 'Standard User'}</span>
          </div>
        </div>
      </td>
      <td>
        ${uEmail ? `<strong>${escapeHtml(uEmail)}</strong>` : '<span style="color:var(--text-subtle)">—</span>'}
      </td>
      <td>
        ${uPhone ? `<code>${escapeHtml(uPhone)}</code>` : '<span style="color:var(--text-subtle)">—</span>'}
      </td>
      <td>${verifiedBadge}</td>
      <td>
        <span class="badge ${userMeds.length > 0 ? 'badge-primary' : 'badge-muted'}">
          ${userMeds.length} medicine${userMeds.length === 1 ? '' : 's'}
        </span>
      </td>
      <td><span style="font-size:12px; color:var(--text-muted);">${formatDateTime(u.created_at)}</span></td>
      <td style="text-align:right;" onclick="event.stopPropagation()">
        <div style="display:flex; justify-content:flex-end; gap:6px; align-items:center;">
          <button class="btn btn-secondary btn-sm" onclick="openUserModalByKey('${escapeHtml(key)}')">
            ℹ️ Details
          </button>
          <button class="action-icon-btn" title="Delete this user" onclick="quickDeleteUser('${escapeHtml(key)}')">
            🗑️
          </button>
        </div>
      </td>
    </tr>`;
  }).join('');

  // Update master checkbox state
  const selectAllBox = document.getElementById('selectAllCheckbox');
  if (selectAllBox) {
    selectAllBox.checked = users.length > 0 && selectedUserKeys.size === users.length;
  }
}

function onRowClick(event, key) {
  // If clicked on input or button, stop
  if (event.target.tagName === 'INPUT' || event.target.tagName === 'BUTTON') return;
  openUserModalByKey(key);
}

function toggleUserSelect(key, isChecked) {
  if (isChecked) {
    selectedUserKeys.add(key);
  } else {
    selectedUserKeys.delete(key);
  }
  updateSelectionBar();
  applyFilter();
}

function toggleSelectAll(masterBox) {
  if (!currentData) return;
  const users = getFilteredUsers();
  if (masterBox.checked) {
    users.forEach(u => selectedUserKeys.add(getUserIdentifier(u)));
  } else {
    selectedUserKeys.clear();
  }
  updateSelectionBar();
  applyFilter();
}

function clearAllSelections() {
  selectedUserKeys.clear();
  const masterBox = document.getElementById('selectAllCheckbox');
  if (masterBox) masterBox.checked = false;
  updateSelectionBar();
  applyFilter();
}

function updateSelectionBar() {
  const bar = document.getElementById('selectionBar');
  const count = selectedUserKeys.size;
  if (count > 0) {
    bar.style.display = 'flex';
    document.getElementById('selectionCountText').textContent = `${count} user${count === 1 ? '' : 's'} selected (ticked)`;
  } else {
    bar.style.display = 'none';
  }
}

function getFilteredUsers() {
  if (!currentData) return [];
  const query = (document.getElementById('searchInput').value || '').toLowerCase().trim();
  const users = currentData.users || [];
  const meds = currentData.medicines || [];

  if (!query) return users;

  return users.filter(u => {
    const nameMatch = (u.name || '').toLowerCase().includes(query);
    const emailMatch = (u.email || '').toLowerCase().includes(query);
    const phoneMatch = (u.phone_number || '').toLowerCase().includes(query);

    // Also search by medicines added by this user
    const userMeds = getUserMedicines(u, meds);
    const medMatch = userMeds.some(m => (m.name || '').toLowerCase().includes(query) || (m.dosage || '').toLowerCase().includes(query));

    return nameMatch || emailMatch || phoneMatch || medMatch;
  });
}

function applyFilter() {
  if (!currentData) return;
  const filtered = getFilteredUsers();
  renderUsersTable(filtered, currentData.medicines || []);
}

/* ==================== USER DETAILS MODAL ==================== */

function openUserModalByKey(key) {
  if (!currentData) return;
  const u = (currentData.users || []).find(user => getUserIdentifier(user) === key);
  if (!u) return;

  activeModalUser = u;
  const meds = currentData.medicines || [];
  const reminders = currentData.reminders || [];
  const logs = currentData.dose_logs || [];

  const uEmail = (u.email || '').toLowerCase().trim();
  const uPhone = (u.phone_number || '').trim();

  // Avatar & Title
  const initial = (u.name || uEmail || uPhone || '?').charAt(0).toUpperCase();
  document.getElementById('mAvatar').textContent = initial;
  document.getElementById('mName').textContent = u.name || 'Anonymous User';
  document.getElementById('mEmailOrPhone').textContent = uEmail || uPhone || 'No contact provided';

  // Details
  document.getElementById('mUserId').textContent = u.id || '—';
  document.getElementById('mRole').innerHTML = u.is_admin ? '<span class="badge badge-purple">Admin</span>' : '<span class="badge badge-muted">Standard User</span>';
  document.getElementById('mVerified').innerHTML = u.is_verified ? '<span class="badge badge-success">✓ Verified</span>' : '<span class="badge badge-warning">Unverified</span>';
  document.getElementById('mCreatedAt').textContent = formatDateTime(u.created_at);
  document.getElementById('mLastLogin').textContent = formatDateTime(u.last_login);
  
  const hasPwd = (u.password || u.security_pin) ? true : false;
  document.getElementById('mPinStatus').innerHTML = hasPwd ? '<span class="badge badge-success">✓ Password/PIN Set</span>' : '<span class="badge badge-muted">None Set</span>';

  const secQ = u.security_question || '—';
  const secA = u.security_answer ? ` (Answer: "${escapeHtml(u.security_answer)}")` : '';
  document.getElementById('mSecQA').textContent = secQ + secA;

  // Filter medicines for this user
  const userMeds = meds.filter(m => 
    (uEmail && (m.email || '').toLowerCase().trim() === uEmail) ||
    (uPhone && (m.phone_number || '').trim() === uPhone)
  );
  document.getElementById('mMedsHeader').textContent = `💊 Medicines Added (${userMeds.length})`;

  const medsContainer = document.getElementById('mMedsList');
  if (!userMeds.length) {
    medsContainer.innerHTML = '<div style="color:var(--text-muted); font-size:13px; padding:12px; background:var(--bg-inner); border-radius:10px;">No medicines have been added yet by this user.</div>';
  } else {
    medsContainer.innerHTML = userMeds.map(m => {
      const unit = m.unit || 'tablets';
      const stock = m.current_stock !== undefined ? m.current_stock : 0;
      const threshold = m.refill_threshold !== undefined ? m.refill_threshold : 5;
      const isLow = stock <= threshold;
      const stockBadge = stock <= 0
        ? `<span class="badge badge-danger">Out of stock (0 ${escapeHtml(unit)})</span>`
        : isLow
          ? `<span class="badge badge-warning">${stock} ${escapeHtml(unit)} (Low stock)</span>`
          : `<span class="badge badge-success">${stock} ${escapeHtml(unit)}</span>`;

      let routineSlots = [];
      try {
        if (m.reminders_json) {
          const parsed = JSON.parse(m.reminders_json);
          routineSlots = parsed.map(r => formatTime(r.hour, r.minute));
        }
      } catch(e) {}
      const routineStr = routineSlots.length > 0 ? routineSlots.join(', ') : 'No reminder slots';

      const durationStr = m.duration_days > 0 ? `${m.duration_days} days` : 'Ongoing / Chronic';

      return `<div class="med-item-card">
        <div>
          <div class="med-title">${escapeHtml(m.name)} <span style="color:var(--primary); font-size:13px;">${escapeHtml(m.dosage || '')}</span></div>
          <div class="med-meta">
            <span class="badge badge-primary" style="margin-right:6px;">${escapeHtml(m.type || 'tablet')}</span>
            <span>🍽️ ${escapeHtml(getInstructionLabel(m.instruction))}</span> · 
            <span>⏳ ${escapeHtml(durationStr)}</span>
          </div>
          <div class="med-meta" style="margin-top:4px;">
            <span>⏰ Routine: <strong>${escapeHtml(routineStr)}</strong></span>
          </div>
        </div>
        <div>
          ${stockBadge}
        </div>
      </div>`;
    }).join('');
  }

  // Filter reminders for this user
  const userReminders = reminders.filter(r => 
    (uEmail && (r.email || '').toLowerCase().trim() === uEmail) ||
    (uPhone && (r.phone_number || '').trim() === uPhone)
  );
  document.getElementById('mRemindersHeader').textContent = `⏰ Routine & Reminder Alarms (${userReminders.length})`;
  const remindersContainer = document.getElementById('mRemindersList');
  if (!userReminders.length) {
    remindersContainer.innerHTML = '<div style="color:var(--text-muted); font-size:13px; padding:12px; background:var(--bg-inner); border-radius:10px;">No reminder alarms scheduled.</div>';
  } else {
    remindersContainer.innerHTML = userReminders.map(r => {
      const med = meds.find(m => m.id === r.medicine_id);
      const medName = med ? med.name : 'Medicine';
      return `<div class="med-item-card">
        <div>
          <strong style="color:var(--primary); font-size:15px;">${formatTime(r.hour, r.minute)}</strong> · 
          <strong>${escapeHtml(medName)}</strong>
          <div class="med-meta">Repeat: ${formatDays(r.days_of_week)}</div>
        </div>
        <div>
          <span class="badge ${r.is_alarm ? 'badge-success' : 'badge-muted'}">${r.is_alarm ? 'Full Alarm' : 'Notification'}</span>
        </div>
      </div>`;
    }).join('');
  }

  // Filter dose logs for this user
  const userLogs = logs.filter(l => 
    (uEmail && (l.email || '').toLowerCase().trim() === uEmail) ||
    (uPhone && (l.phone_number || '').trim() === uPhone)
  );
  document.getElementById('mLogsHeader').textContent = `📋 Dose Intake History (${userLogs.length})`;
  const logsContainer = document.getElementById('mLogsList');
  if (!userLogs.length) {
    logsContainer.innerHTML = '<div style="color:var(--text-muted); font-size:13px; padding:12px; background:var(--bg-inner); border-radius:10px;">No dose intake history logged yet.</div>';
  } else {
    logsContainer.innerHTML = userLogs.map(l => {
      const isTaken = l.status === 'taken';
      const statusBadge = isTaken ? '<span class="badge badge-success">✓ Taken</span>' : '<span class="badge badge-danger">✕ Skipped</span>';
      return `<div class="med-item-card">
        <div>
          <strong>${formatDateTime(l.scheduled_time)}</strong>
          <div class="med-meta">Recorded: ${formatDateTime(l.taken_at)}</div>
        </div>
        <div>${statusBadge}</div>
      </div>`;
    }).join('');
  }

  document.getElementById('userModal').style.display = 'flex';
}

function closeUserModal(e) {
  document.getElementById('userModal').style.display = 'none';
  activeModalUser = null;
}

/* ==================== DELETE HANDLERS ==================== */

async function quickDeleteUser(key) {
  if (!currentData) return;
  const u = (currentData.users || []).find(user => getUserIdentifier(user) === key);
  if (!u) return;

  const label = u.email || u.phone_number || u.name || 'User';
  const ok = confirm(`Are you sure you want to permanently delete user "${u.name || 'User'}" (${label})?\n\n` +
    `• Account will be permanently deleted from Supabase Cloud.\n` +
    `• All associated medicines, reminders, and dose logs will be removed.\n` +
    `• The user's mobile app will automatically log out silently and reset to Sign In / Sign Up.\n\n` +
    `Do you want to proceed?`);

  if (!ok) return;

  await executeDeleteUsers([{
    userId: u.id,
    email: u.email,
    phone: u.phone_number
  }], `Deleted user ${label}`);
}

async function deleteUserFromModal() {
  if (!activeModalUser) return;
  const u = activeModalUser;
  const label = u.email || u.phone_number || u.name || 'User';

  const ok = confirm(`Delete account "${u.name}" (${label}) from Supabase Cloud?\n\n` +
    `This will immediately erase the account, medicines, and logs.\n` +
    `Their mobile app will be automatically signed out.\n\nProceed?`);

  if (!ok) return;

  closeUserModal();
  await executeDeleteUsers([{
    userId: u.id,
    email: u.email,
    phone: u.phone_number
  }], `Deleted user ${label}`);
}

async function deleteSelectedUsers() {
  if (!currentData || selectedUserKeys.size === 0) return;

  const usersToDelete = (currentData.users || []).filter(u => selectedUserKeys.has(getUserIdentifier(u)));
  const count = usersToDelete.length;

  const ok = confirm(`Are you sure you want to delete ${count} SELECTED USER(S)?\n\n` +
    usersToDelete.map(u => `• ${u.name || 'User'} (${u.email || u.phone_number})`).join('\n') +
    `\n\nAll their medicines, alarms, and history will be permanently deleted from Supabase Cloud.\n` +
    `Proceed with bulk deletion?`);

  if (!ok) return;

  const payload = usersToDelete.map(u => ({
    userId: u.id,
    email: u.email,
    phone: u.phone_number
  }));

  await executeDeleteUsers(payload, `Successfully deleted ${count} user(s)`);
}

async function executeDeleteUsers(usersList, successMsg) {
  showNotice('Deleting user(s) from Supabase Cloud...', false);
  try {
    const res = await fetch('/api/delete_user', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ users: usersList })
    });
    const result = await res.json();
    if (result.success) {
      showNotice(`✓ ${successMsg}!`, false);
      selectedUserKeys.clear();
      await loadData(true);
    } else {
      showNotice(`Failed to delete: ${result.message}`, true);
    }
  } catch (err) {
    showNotice(`Delete request error: ${err.message}`, true);
  }
}

function exportJSON() {
  if (!currentData) return;
  const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(currentData, null, 2));
  const downloadAnchor = document.createElement('a');
  downloadAnchor.setAttribute("href", dataStr);
  downloadAnchor.setAttribute("download", `mediremind_users_export_${new Date().toISOString().split('T')[0]}.json`);
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

// Close modal on Escape key
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeUserModal();
});

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
            data = get_combined_data(force_cloud=force_cloud)
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

        if path == "/api/delete_user":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")
            try:
                params = json.loads(body)
            except Exception:
                params = {}

            # Support either "users" list or single user fields
            users_to_delete = params.get("users")
            if not users_to_delete:
                user_id = params.get("userId") or params.get("id")
                email = params.get("email")
                phone = params.get("phone") or params.get("phone_number")
                users_to_delete = [{"userId": user_id, "email": email, "phone": phone}]

            success, msg = delete_users_from_supabase(users_to_delete)
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps({"success": success, "message": msg}, ensure_ascii=False).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

def main():
    parser = argparse.ArgumentParser(description="MediRemind User Management Admin Dashboard")
    parser.add_argument("--port", type=int, default=8080, help="Port to run web server on (default: 8080)")
    parser.add_argument("--no-browser", action="store_true", help="Do not automatically open browser")
    parser.add_argument("--test", action="store_true", help="Run self-test and exit immediately")
    args = parser.parse_args()

    if args.test:
        print("[TEST] Fetching data...")
        data = get_combined_data()
        print(f"[TEST] Source: {data.get('data_source')}, Status: {data.get('status')}")
        print(f"[TEST] Users: {len(data.get('users', []))}, Medicines: {len(data.get('medicines', []))}")
        return

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

    url = f"http://localhost:{port}"

    print("Connecting to Supabase Cloud...")
    initial_data = get_combined_data()
    u_count = len(initial_data.get("users", []))
    m_count = len(initial_data.get("medicines", []))
    source = initial_data.get("data_source", "unknown")

    print("=" * 68)
    print("  💊 MediRemind - Users Admin Panel")
    print(f"  🌐 Portal Web URL:   {url}")
    print(f"  ☁️  Data Source:      {source.upper()}")
    print(f"  👥 Registered Users: {u_count}")
    print(f"  💊 Total Medicines:  {m_count}")
    print("=" * 68)
    print("Opening browser... (Press Ctrl+C in terminal to stop server)\n")

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
