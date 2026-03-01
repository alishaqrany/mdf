# MDF Academy API — Moodle Local Plugin

> Custom web-service plugin for the **MDF Academy** Flutter mobile app.  
> Provides admin dashboard statistics, bulk enrolment, activity logs, system health monitoring, and Firebase push notifications.

## Requirements

| Requirement | Version |
|---|---|
| Moodle | 4.1+ (build ≥ 2022112800) |
| PHP | 8.0+ |
| Database | MySQL / MariaDB / PostgreSQL |

## Installation

1. **Copy the plugin folder** into your Moodle installation:

   ```bash
   cp -r local_mdf_api /path/to/moodle/local/mdf_api
   ```

2. **Visit** Site Administration → Notifications to trigger the database upgrade.

3. **Enable the web service** (if not already):
   - Site Administration → Advanced features → Enable web services ✓
   - Site Administration → Plugins → Web services → External services → **MDF Academy Mobile Service** should appear automatically.

4. **Configure push notifications** (optional):
   - Site Administration → Plugins → Local plugins → **MDF Academy API**
   - Enable push notifications ✓
   - Paste your **FCM Server Key** from Firebase Console → Project Settings → Cloud Messaging.

---

## Web Service Functions

All functions are registered under the service **`mdf_mobile`** (MDF Academy Mobile Service).

### 1. `local_mdf_api_get_dashboard_stats`

Returns high-level platform statistics for the admin dashboard.

**Capability:** `local/mdf_api:viewstats`  
**Type:** Read

**Parameters:** None

**Returns:**
| Field | Type | Description |
|---|---|---|
| `total_users` | int | Total registered users |
| `active_users` | int | Users active in last 30 days |
| `online_users` | int | Users active in last 5 minutes |
| `total_courses` | int | Total visible courses |
| `total_enrollments` | int | Total enrolment records |
| `new_users_month` | int | New users this month |
| `new_users_week` | int | New users this week |
| `completions_month` | int | Course completions this month |
| `avg_progress` | float | Average grade across all users |
| `total_categories` | int | Total course categories |
| `disk_usage_bytes` | int | Total file storage in bytes |

---

### 2. `local_mdf_api_get_enrollment_stats`

Returns enrolment/completion trends over time.

**Capability:** `local/mdf_api:viewstats`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `period` | string | `month` | Aggregation period: `month`, `week`, `day` |
| `months` | int | `6` | Lookback period (max 24) |
| `courseid` | int | `0` | Filter by course (0 = all) |

**Returns:** `periods[]` array with `{ label, new_enrollments, completions, new_users }` + `summary` object.

---

### 3. `local_mdf_api_bulk_enrol_users`

Enrol multiple users into a course at once.

**Capability:** `local/mdf_api:bulkenrol`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `courseid` | int | required | Target course ID |
| `userids` | int[] | required | Array of user IDs |
| `roleid` | int | `5` | Role ID (5 = student) |
| `timestart` | int | `0` | Enrolment start (0 = now) |
| `timeend` | int | `0` | Enrolment end (0 = unlimited) |

**Returns:** `{ total_requested, total_success, total_failed, success[], failed[] }`

---

### 4. `local_mdf_api_get_activity_logs`

Query the standard log store with flexible filters.

**Capability:** `local/mdf_api:viewlogs`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `userid` | int | `0` | Filter by user (0 = all) |
| `courseid` | int | `0` | Filter by course (0 = all) |
| `component` | string | `""` | Filter by component |
| `action` | string | `""` | Filter by action |
| `timestart` | int | `0` | Start timestamp |
| `timeend` | int | `0` | End timestamp |
| `page` | int | `0` | Page number (0-based) |
| `perpage` | int | `50` | Results per page (max 200) |

**Returns:** `{ logs[], total, page, perpage, haspages }`

---

### 5. `local_mdf_api_get_system_health`

Returns server and Moodle health information.

**Capability:** `local/mdf_api:viewstats`  
**Type:** Read

**Parameters:** None

**Returns:**
| Field | Type | Description |
|---|---|---|
| `moodle_version` | string | Moodle release string |
| `php_version` | string | PHP version |
| `db_type` | string | Database engine |
| `db_size_bytes` | int | Database size |
| `dataroot_size_bytes` | int | Moodledata directory size |
| `free_disk_bytes` | int | Free disk space |
| `last_cron_time` | int | Last cron execution |
| `cron_overdue` | int | 1 if cron is overdue (>10 min) |
| `memory_usage_bytes` | int | Current PHP memory usage |
| `pending_adhoc_tasks` | int | Pending background tasks |
| `failed_tasks_24h` | int | Failed tasks in last 24h |

---

### 6. `local_mdf_api_send_push_notification`

Send push notifications to users via Firebase Cloud Messaging.

**Capability:** `local/mdf_api:sendnotification`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `userids` | int[] | required | Target user IDs |
| `title` | string | required | Notification title |
| `body` | string | required | Notification body |
| `data` | string | `"{}"` | JSON payload |

**Returns:** `{ total_sent, total_failed, results[] }`

---

### 7. `local_mdf_api_register_fcm_token`

Register or update an FCM device token for the authenticated user.

**Capability:** None (authenticated users only)  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `token` | string | required | FCM device token |
| `platform` | string | required | `android` or `ios` |
| `devicename` | string | `""` | Device name |

**Returns:** `{ success, action, tokenid }`

---

## Event Observers (Auto Push)

When push notifications are enabled, the plugin automatically sends notifications for:

| Moodle Event | Recipient | Notification |
|---|---|---|
| `user_enrolment_created` | Enrolled user | "You have been enrolled in: {course}" |
| `course_completed` | Completing user | "Congratulations! You completed: {course}" |
| `assessable_submitted` | Course teachers | "{student} submitted an assignment in {course}" |
| `user_graded` | Graded user | "A new grade has been posted in: {course}" |
| `post_created` | Course participants | "{author} posted: {subject}" |

---

## Database Tables

| Table | Purpose |
|---|---|
| `local_mdf_fcm_tokens` | Stores FCM device tokens per user |
| `local_mdf_push_log` | Logs all sent push notifications |

---

## Capabilities

| Capability | Default Roles |
|---|---|
| `local/mdf_api:viewstats` | Manager, Editing Teacher |
| `local/mdf_api:viewlogs` | Manager |
| `local/mdf_api:bulkenrol` | Manager, Editing Teacher |
| `local/mdf_api:sendnotification` | Manager |

---

## Plugin Settings

Navigate to: **Site Administration → Plugins → Local plugins → MDF Academy API**

| Setting | Description |
|---|---|
| Enable push notifications | Toggle FCM push for event observers |
| FCM Server Key | Firebase Cloud Messaging legacy server key |

---

## File Structure

```
local_mdf_api/
├── version.php                              # Plugin version & requirements
├── settings.php                             # Admin settings page
├── db/
│   ├── services.php                         # Web service function definitions
│   ├── access.php                           # Capability definitions
│   ├── install.xml                          # Database table schemas
│   └── events.php                           # Event observer registration
├── classes/
│   ├── observer.php                         # Event handler → FCM push
│   └── external/
│       ├── get_dashboard_stats.php          # Dashboard statistics
│       ├── get_enrollment_stats.php         # Enrolment trends
│       ├── bulk_enrol_users.php             # Bulk enrolment
│       ├── get_activity_logs.php            # Activity log query
│       ├── get_system_health.php            # Server health
│       ├── send_push_notification.php       # Manual FCM push
│       └── register_fcm_token.php           # FCM token registration
├── lang/
│   ├── en/local_mdf_api.php                 # English strings
│   └── ar/local_mdf_api.php                 # Arabic strings
└── README.md                                # This file
```

---

## License

GNU GPL v3 or later — http://www.gnu.org/copyleft/gpl.html
