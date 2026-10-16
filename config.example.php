<?php
// config.example.php
// ─────────────────────────────────────────────────────────────────────────────
// CLEAN N RIDE - DATABASE CONFIGURATION TEMPLATE
// 
// Instructions:
// 1. Copy this file to `config.local.php` in the project root:
//      cp config.example.php config.local.php
// 2. Adjust credentials below to match your MySQL database setup.
// 3. NEVER commit `config.local.php` to version control (it is git-ignored).
// ─────────────────────────────────────────────────────────────────────────────

define('DB_HOST',    'localhost');
define('DB_NAME',    'cleannride_crm');
define('DB_USER',    'root');
define('DB_PASS',    '');
define('DB_CHARSET', 'utf8mb4');
