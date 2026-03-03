# MDF Academy API — Moodle Local Plugin

> Custom web-service plugin for the **MDF Academy** Flutter mobile app.  
> Provides admin dashboard statistics, bulk enrolment, activity logs, system health monitoring, Firebase push notifications, **gamification** (points, badges, challenges, leaderboards, streaks), and **social learning** (study groups, shared notes, peer review, collaborative sessions).

**Version:** 2.0.0 (build 2026030200)

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

## Gamification API

### 8. `local_mdf_api_get_user_points`

Returns the gamification profile for the current user (points, level, rank, streak).

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Read

**Parameters:** None

**Returns:**
| Field | Type | Description |
|---|---|---|
| `totalpoints` | int | Lifetime points |
| `currentlevel` | int | Current level (1–20) |
| `currentstreak` | int | Consecutive login days |
| `longeststreak` | int | Best ever streak |
| `rank` | int | Global rank by points |
| `lastlogindate` | string | Last recorded login (Y-m-d) |

---

### 9. `local_mdf_api_get_point_history`

Returns paginated point transaction history for the current user.

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | int | `0` | Page number (0-based) |
| `perpage` | int | `20` | Items per page (max 100) |

**Returns:** `{ transactions[] }` — each with `{ id, points, action, description, timecreated }`

---

### 10. `local_mdf_api_award_points`

Award points to a user (admin-only).

**Capability:** `local/mdf_api:awardpoints`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `userid` | int | required | Target user ID |
| `points` | int | required | Points to award |
| `action` | string | required | Action key (e.g. `manual_award`) |
| `description` | string | `""` | Optional description |

**Returns:** `{ success, newtotal, newlevel }`

---

### 11. `local_mdf_api_record_daily_login`

Records a daily login, updates streak, and awards login points.

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Write

**Parameters:** None

**Returns:** `{ currentstreak, longeststreak, pointsawarded, streakbonus }`

---

### 12. `local_mdf_api_get_all_badges`

Returns all available badges with earned status for the current user.

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Read

**Parameters:** None

**Returns:** `{ badges[] }` — each with `{ id, name, description, iconurl, criteria, criteriatype, criteriavalue, earned, earnedat }`

---

### 13. `local_mdf_api_get_earned_badges`

Returns only the badges the current user has earned.

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Read

**Parameters:** None

**Returns:** `{ badges[] }` — same structure as `get_all_badges`

---

### 14. `local_mdf_api_get_badge_detail`

Returns detailed information about a single badge.

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `badgeid` | int | required | Badge ID |

**Returns:** `{ id, name, description, iconurl, criteria, criteriatype, criteriavalue, earned, earnedat, earnedpercentage }`

---

### 15. `local_mdf_api_get_leaderboard`

Returns the global leaderboard sorted by points.

**Capability:** `local/mdf_api:viewleaderboard`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `period` | string | `all` | `all`, `weekly`, or `monthly` |
| `limit` | int | `50` | Max entries (max 100) |

**Returns:** `{ entries[] }` — each with `{ rank, userid, fullname, profileimageurl, totalpoints, currentlevel }`

---

### 16. `local_mdf_api_get_active_challenges`

Returns active (in-progress or available) challenges for the current user.

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Read

**Parameters:** None

**Returns:** `{ challenges[] }` — each with `{ id, name, description, challengetype, targetvalue, rewardpoints, startdate, enddate, progress, status }`

---

### 17. `local_mdf_api_get_completed_challenges`

Returns completed/claimed challenges for the current user.

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Read

**Parameters:** None

**Returns:** `{ challenges[] }` — same structure as `get_active_challenges`

---

### 18. `local_mdf_api_claim_challenge_reward`

Claims the reward points for a completed challenge.

**Capability:** `local/mdf_api:viewgamification`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `challengeid` | int | required | Challenge ID |

**Returns:** `{ success, pointsawarded, newtotal }`

---

## Social Learning API — Study Groups

### 19. `local_mdf_api_get_study_groups`

Returns all study groups the current user can see (public groups + groups they belong to).

**Capability:** `local/mdf_api:viewstudygroups`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `courseid` | int | `0` | Filter by course (0 = all) |

**Returns:** `{ groups[] }` — each with `{ id, name, description, courseid, coursename, isprivate, maxmembers, membercount, isadmin, ismember, createdby, timecreated }`

---

### 20. `local_mdf_api_get_study_group_detail`

Returns detailed info about a study group including its members list.

**Capability:** `local/mdf_api:viewstudygroups`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |

**Returns:** `{ id, name, description, courseid, coursename, isprivate, maxmembers, membercount, isadmin, ismember, createdby, timecreated, members[] }` — each member has `{ userid, fullname, profileimageurl, role, timejoined, isonline }`

---

### 21. `local_mdf_api_create_study_group`

Creates a new study group. The creator is automatically added as admin member.

**Capability:** `local/mdf_api:managestudygroups`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | Group name |
| `description` | string | `""` | Group description |
| `courseid` | int | required | Associated course ID |
| `isprivate` | int | `0` | 1 = private, 0 = public |
| `maxmembers` | int | `50` | Maximum members |

**Returns:** `{ id, name, description, courseid, isprivate, maxmembers, membercount, timecreated }`

---

### 22. `local_mdf_api_join_study_group`

Join a study group.

**Capability:** `local/mdf_api:viewstudygroups`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |

**Returns:** `{ success, message }`

---

### 23. `local_mdf_api_leave_study_group`

Leave a study group. The last admin cannot leave.

**Capability:** `local/mdf_api:viewstudygroups`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |

**Returns:** `{ success, message }`

---

### 24. `local_mdf_api_get_group_members`

Returns the members of a study group.

**Capability:** `local/mdf_api:viewstudygroups`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |

**Returns:** `{ members[] }` — each with `{ userid, fullname, profileimageurl, role, timejoined, isonline }`

---

### 25. `local_mdf_api_update_group_member_role`

Change a member's role (admin ↔ member). Requires group admin.

**Capability:** `local/mdf_api:managestudygroups`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |
| `userid` | int | required | Target user ID |
| `role` | string | required | `admin` or `member` |

**Returns:** `{ success, message }`

---

### 26. `local_mdf_api_delete_study_group`

Deletes a study group and all associated data (members, sessions, notes).

**Capability:** `local/mdf_api:managestudygroups`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |

**Returns:** `{ success, message }`

---

## Social Learning API — Study Notes

### 27. `local_mdf_api_get_course_notes`

Returns shared study notes for a course.

**Capability:** `local/mdf_api:managenotes`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `courseid` | int | required | Course ID |
| `page` | int | `0` | Page number (0-based) |
| `perpage` | int | `20` | Items per page (max 100) |

**Returns:** `{ notes[] }` — each with `{ id, title, content, courseid, groupid, authorid, authorname, authorimage, likescount, isliked, isbookmarked, commentscount, timecreated, timemodified }`

---

### 28. `local_mdf_api_get_group_notes`

Returns shared study notes filtered by group.

**Capability:** `local/mdf_api:managenotes`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |
| `page` | int | `0` | Page number |
| `perpage` | int | `20` | Items per page (max 100) |

**Returns:** `{ notes[] }` — same structure as `get_course_notes`

---

### 29. `local_mdf_api_create_note`

Creates a new study note. Awards 10 gamification points.

**Capability:** `local/mdf_api:managenotes`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `title` | string | required | Note title |
| `content` | string | required | Note content |
| `courseid` | int | required | Course ID |
| `groupid` | int | `0` | Optional group ID |

**Returns:** `{ id, title, content, courseid, groupid, authorid, timecreated }`

---

### 30. `local_mdf_api_update_note`

Updates an existing note (author only).

**Capability:** `local/mdf_api:managenotes`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `noteid` | int | required | Note ID |
| `title` | string | required | New title |
| `content` | string | required | New content |

**Returns:** `{ success, message }`

---

### 31. `local_mdf_api_delete_note`

Deletes a note and all associated likes, bookmarks, and comments.

**Capability:** `local/mdf_api:managenotes`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `noteid` | int | required | Note ID |

**Returns:** `{ success, message }`

---

### 32. `local_mdf_api_toggle_like_note`

Toggles a like on a study note.

**Capability:** `local/mdf_api:managenotes`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `noteid` | int | required | Note ID |

**Returns:** `{ liked, likescount }`

---

### 33. `local_mdf_api_toggle_bookmark_note`

Toggles a bookmark on a study note.

**Capability:** `local/mdf_api:managenotes`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `noteid` | int | required | Note ID |

**Returns:** `{ bookmarked }`

---

### 34. `local_mdf_api_get_note_comments`

Returns comments on a study note.

**Capability:** `local/mdf_api:managenotes`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `noteid` | int | required | Note ID |

**Returns:** `{ comments[] }` — each with `{ id, noteid, userid, fullname, profileimageurl, content, timecreated }`

---

### 35. `local_mdf_api_add_note_comment`

Adds a comment to a study note.

**Capability:** `local/mdf_api:managenotes`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `noteid` | int | required | Note ID |
| `content` | string | required | Comment text |

**Returns:** `{ id, noteid, userid, fullname, profileimageurl, content, timecreated }`

---

## Social Learning API — Peer Review

### 36. `local_mdf_api_get_pending_reviews`

Returns workshop submissions awaiting review by the current user.

**Capability:** `local/mdf_api:viewpeerreviews`  
**Type:** Read

**Parameters:** None

**Returns:** `{ reviews[] }` — each with `{ id, submissionid, workshopid, workshopname, courseid, authorid, authorname, title, content, grade, feedbackauthor, timecreated, timemodified }`

---

### 37. `local_mdf_api_get_completed_reviews`

Returns reviews already completed by the current user.

**Capability:** `local/mdf_api:viewpeerreviews`  
**Type:** Read

**Parameters:** None

**Returns:** `{ reviews[] }` — same structure as `get_pending_reviews`

---

### 38. `local_mdf_api_get_review_detail`

Returns details of a single peer review assessment.

**Capability:** `local/mdf_api:viewpeerreviews`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `assessmentid` | int | required | Assessment ID |

**Returns:** `{ id, submissionid, workshopid, workshopname, courseid, authorid, authorname, title, content, grade, feedbackauthor, timecreated, timemodified }`

---

### 39. `local_mdf_api_submit_review`

Submits a peer review for a workshop submission. Awards 15 gamification points.

**Capability:** `local/mdf_api:submitreview`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `assessmentid` | int | required | Assessment ID |
| `grade` | float | required | Grade (0–100) |
| `feedback` | string | `""` | Written feedback |

**Returns:** `{ success, message }`

---

## Social Learning API — Collaborative Sessions

### 40. `local_mdf_api_get_group_sessions`

Returns collaborative study sessions for a group.

**Capability:** `local/mdf_api:managesessions`  
**Type:** Read

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |

**Returns:** `{ sessions[] }` — each with `{ id, groupid, title, description, scheduledstart, scheduledend, status, createdby, creatorname, participantcount, timecreated }`

---

### 41. `local_mdf_api_create_session`

Creates a collaborative session. The creator is auto-joined.

**Capability:** `local/mdf_api:managesessions`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `groupid` | int | required | Group ID |
| `title` | string | required | Session title |
| `description` | string | `""` | Session description |
| `scheduledstart` | int | required | Start timestamp |
| `scheduledend` | int | required | End timestamp |

**Returns:** `{ id, groupid, title, description, scheduledstart, scheduledend, status, createdby, timecreated }`

---

### 42. `local_mdf_api_join_session`

Join a collaborative session.

**Capability:** `local/mdf_api:managesessions`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `sessionid` | int | required | Session ID |

**Returns:** `{ success, message }`

---

### 43. `local_mdf_api_leave_session`

Leave a collaborative session.

**Capability:** `local/mdf_api:managesessions`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `sessionid` | int | required | Session ID |

**Returns:** `{ success, message }`

---

### 44. `local_mdf_api_end_session`

End a collaborative session (creator or group admin only).

**Capability:** `local/mdf_api:managesessions`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `sessionid` | int | required | Session ID |

**Returns:** `{ success, message }`

---

### 45. `local_mdf_api_add_session_note`

Add a note to a collaborative session.

**Capability:** `local/mdf_api:managesessions`  
**Type:** Write

| Parameter | Type | Default | Description |
|---|---|---|---|
| `sessionid` | int | required | Session ID |
| `content` | string | required | Note content |

**Returns:** `{ id, sessionid, userid, fullname, content, timecreated }`

---

## Event Observers (Auto Push + Gamification)

When push notifications and gamification are enabled, the plugin automatically handles:

| Moodle Event | Push Notification | Gamification |
|---|---|---|
| `user_enrolment_created` | "You have been enrolled in: {course}" → enrolled user | +10 points (`course_enroll`) |
| `course_completed` | "Congratulations! You completed: {course}" → completing user | +100 points (`module_complete`) |
| `assessable_submitted` | "{student} submitted an assignment in {course}" → teachers | +20 points (`assignment_submit`) |
| `user_graded` | "A new grade has been posted in: {course}" → graded user | +15 points (`quiz_complete`) |
| `post_created` | "{author} posted: {subject}" → course participants | +5 points (`forum_post`) |

Additionally, gamification points are awarded for in-app actions:
- **Creating a study note:** +10 points
- **Submitting a peer review:** +15 points
- **Daily login:** +5 points (+ streak bonus every 7 days)

---

## Database Tables

| Table | Purpose |
|---|---|
| `local_mdf_fcm_tokens` | FCM device tokens per user |
| `local_mdf_push_log` | Sent push notification log |
| `local_mdf_user_points` | Per-user gamification totals, level, streak |
| `local_mdf_point_transactions` | Point award history/ledger |
| `local_mdf_badges` | Badge definitions (criteria, icon) |
| `local_mdf_user_badges` | Badges earned by users |
| `local_mdf_challenges` | Challenge definitions (type, target, reward) |
| `local_mdf_user_challenges` | Per-user challenge progress |
| `local_mdf_study_groups` | Study group definitions |
| `local_mdf_group_members` | Group membership + roles |
| `local_mdf_study_notes` | Shared study notes |
| `local_mdf_note_likes` | Note like records |
| `local_mdf_note_bookmarks` | Note bookmark records |
| `local_mdf_note_comments` | Note comment threads |
| `local_mdf_collab_sessions` | Collaborative study sessions |
| `local_mdf_session_participants` | Session participant records |
| `local_mdf_session_notes` | Notes added during sessions |

---

## Capabilities

| Capability | Description | Default Roles |
|---|---|---|
| `local/mdf_api:viewstats` | View admin dashboard stats | Manager, Editing Teacher |
| `local/mdf_api:viewlogs` | View activity logs | Manager |
| `local/mdf_api:bulkenrol` | Bulk-enrol users | Manager, Editing Teacher |
| `local/mdf_api:sendnotification` | Send push notifications | Manager |
| `local/mdf_api:viewgamification` | View gamification data | Manager, Teacher, Student |
| `local/mdf_api:managegamification` | Manage gamification settings | Manager |
| `local/mdf_api:awardpoints` | Award points to users | Manager, Teacher |
| `local/mdf_api:viewleaderboard` | View leaderboard | Manager, Teacher, Student |
| `local/mdf_api:managestudygroups` | Create/manage study groups | Manager, Teacher, Student |
| `local/mdf_api:viewstudygroups` | View/join study groups | Manager, Teacher, Student |
| `local/mdf_api:managenotes` | Create/manage study notes | Manager, Teacher, Student |
| `local/mdf_api:viewpeerreviews` | View peer review assignments | Manager, Teacher, Student |
| `local/mdf_api:submitreview` | Submit peer reviews | Manager, Teacher, Student |
| `local/mdf_api:managesessions` | Manage collaborative sessions | Manager, Teacher, Student |

---

## Plugin Settings

Navigate to: **Site Administration → Plugins → Local plugins → MDF Academy API**

### Push Notifications
| Setting | Description |
|---|---|
| Enable push notifications | Toggle FCM push for event observers |
| FCM Server Key | Firebase Cloud Messaging legacy server key |

### Gamification
| Setting | Description |
|---|---|
| Enable gamification | Toggle the gamification system |
| Points — Course enrolment | Points awarded for enrolling in a course (default: 10) |
| Points — Module completion | Points awarded for completing a course (default: 100) |
| Points — Assignment submission | Points awarded for submitting an assignment (default: 20) |
| Points — Quiz completion | Points awarded for a quiz/grade event (default: 15) |
| Points — Forum post | Points awarded for creating a forum post (default: 5) |

### Social Learning
| Setting | Description |
|---|---|
| Enable social learning | Toggle social learning features |
| Max group members | Maximum members per study group (default: 50) |
| Max session participants | Maximum participants per collaborative session (default: 30) |

---

## File Structure

```
local_mdf_api/
├── version.php                              # Plugin version & requirements
├── settings.php                             # Admin settings page
├── db/
│   ├── services.php                         # Web service function definitions (45 functions)
│   ├── access.php                           # Capability definitions (15 capabilities)
│   ├── install.xml                          # Database table schemas (16 tables)
│   ├── upgrade.php                          # Database migration (v2.0 tables + seed data)
│   └── events.php                           # Event observer registration
├── classes/
│   ├── observer.php                         # Event handler → push + gamification
│   ├── gamification_helper.php              # Shared gamification business logic
│   └── external/
│       ├── get_dashboard_stats.php          # Admin: dashboard statistics
│       ├── get_enrollment_stats.php         # Admin: enrolment trends
│       ├── bulk_enrol_users.php             # Admin: bulk enrolment
│       ├── get_activity_logs.php            # Admin: activity log query
│       ├── get_system_health.php            # Admin: server health
│       ├── send_push_notification.php       # Admin: manual FCM push
│       ├── register_fcm_token.php           # User: FCM token registration
│       ├── get_user_points.php              # Gamification: user profile
│       ├── get_point_history.php            # Gamification: transaction history
│       ├── award_points.php                 # Gamification: admin award
│       ├── record_daily_login.php           # Gamification: daily login
│       ├── get_all_badges.php               # Gamification: all badges
│       ├── get_earned_badges.php            # Gamification: earned badges
│       ├── get_badge_detail.php             # Gamification: badge detail
│       ├── get_leaderboard.php              # Gamification: leaderboard
│       ├── get_active_challenges.php        # Gamification: active challenges
│       ├── get_completed_challenges.php     # Gamification: completed challenges
│       ├── claim_challenge_reward.php       # Gamification: claim reward
│       ├── get_study_groups.php             # Social: list groups
│       ├── get_study_group_detail.php       # Social: group detail + members
│       ├── create_study_group.php           # Social: create group
│       ├── join_study_group.php             # Social: join group
│       ├── leave_study_group.php            # Social: leave group
│       ├── get_group_members.php            # Social: group members
│       ├── update_group_member_role.php     # Social: change role
│       ├── delete_study_group.php           # Social: delete group
│       ├── get_course_notes.php             # Notes: course notes
│       ├── get_group_notes.php              # Notes: group notes
│       ├── create_note.php                  # Notes: create note
│       ├── update_note.php                  # Notes: update note
│       ├── delete_note.php                  # Notes: delete note
│       ├── toggle_like_note.php             # Notes: toggle like
│       ├── toggle_bookmark_note.php         # Notes: toggle bookmark
│       ├── get_note_comments.php            # Notes: list comments
│       ├── add_note_comment.php             # Notes: add comment
│       ├── get_pending_reviews.php          # Review: pending reviews
│       ├── get_completed_reviews.php        # Review: completed reviews
│       ├── get_review_detail.php            # Review: review detail
│       ├── submit_review.php               # Review: submit review
│       ├── get_group_sessions.php           # Sessions: list sessions
│       ├── create_session.php               # Sessions: create session
│       ├── join_session.php                 # Sessions: join session
│       ├── leave_session.php                # Sessions: leave session
│       ├── end_session.php                  # Sessions: end session
│       └── add_session_note.php             # Sessions: add note
├── lang/
│   ├── en/local_mdf_api.php                 # English strings
│   └── ar/local_mdf_api.php                 # Arabic strings
└── README.md                                # This file
```

---

## Seed Data

On upgrade to v2.0, the plugin automatically creates:

### 15 Default Badges
| Category | Badges |
|---|---|
| Completions | First Course, 5 Courses, 10 Courses |
| Points | 100 Points, 500 Points, 1000 Points, 5000 Points |
| Streaks | 7-Day Streak, 30-Day Streak |
| Social | First Note, 10 Notes, First Group, 5 Groups |
| Reviews | First Review, 10 Reviews |

### 7 Default Challenges
| Challenge | Type | Target | Reward |
|---|---|---|---|
| Weekly Learner | completions | 3 completions | 50 pts |
| Point Collector | points | 200 points | 30 pts |
| Social Butterfly | notes | 5 notes | 40 pts |
| Discussion Leader | forum_posts | 10 posts | 35 pts |
| Perfect Week | login_streak | 7 days | 75 pts |
| Quiz Master | quiz_completions | 5 quizzes | 60 pts |
| Team Player | group_joins | 3 groups | 45 pts |

---

## License

GNU GPL v3 or later — http://www.gnu.org/copyleft/gpl.html
