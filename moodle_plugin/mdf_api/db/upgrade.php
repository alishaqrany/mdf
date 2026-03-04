<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Moodle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.  If not, see <http://www.gnu.org/licenses/>.

/**
 * Database upgrade steps for local_mdf_api.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

function xmldb_local_mdf_api_upgrade($oldversion) {
    global $DB;
    $dbman = $DB->get_manager();

    // =====================================================================
    // v2.0.0 — Gamification + Social Learning tables.
    // =====================================================================
    if ($oldversion < 2026030200) {

        // ─── GAMIFICATION TABLES ─────────────────────────────────────

        // 1. local_mdf_user_points — XP/level profile per user.
        $table = new xmldb_table('local_mdf_user_points');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',                XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('userid',            XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('totalpoints',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('level',             XMLDB_TYPE_INTEGER, '5',  null, XMLDB_NOTNULL, null, '1');
            $table->add_field('currentlevelpoints', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('nextlevelpoints',   XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '100');
            $table->add_field('currentstreak',     XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('longeststreak',     XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('lastactivitydate',  XMLDB_TYPE_INTEGER, '10', null, null);
            $table->add_field('timecreated',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timemodified',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('userid_unique', XMLDB_INDEX_UNIQUE, ['userid']);

            $dbman->create_table($table);
        }

        // 2. local_mdf_point_transactions — point history ledger.
        $table = new xmldb_table('local_mdf_point_transactions');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',           XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('userid',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('points',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('action',       XMLDB_TYPE_CHAR,   '50', null, XMLDB_NOTNULL);
            $table->add_field('description',  XMLDB_TYPE_CHAR,  '255', null, null);
            $table->add_field('referenceid',  XMLDB_TYPE_INTEGER, '10', null, null);
            $table->add_field('timecreated',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('userid_time_idx', XMLDB_INDEX_NOTUNIQUE, ['userid', 'timecreated']);
            $table->add_index('action_idx', XMLDB_INDEX_NOTUNIQUE, ['action']);

            $dbman->create_table($table);
        }

        // 3. local_mdf_badges — badge definitions.
        $table = new xmldb_table('local_mdf_badges');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',             XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('name',           XMLDB_TYPE_CHAR,   '100', null, XMLDB_NOTNULL);
            $table->add_field('description',    XMLDB_TYPE_TEXT,    null,  null, null);
            $table->add_field('iconname',       XMLDB_TYPE_CHAR,   '100', null, XMLDB_NOTNULL, null, 'star');
            $table->add_field('category',       XMLDB_TYPE_CHAR,   '50',  null, XMLDB_NOTNULL, null, 'general');
            $table->add_field('rarity',         XMLDB_TYPE_CHAR,   '20',  null, XMLDB_NOTNULL, null, 'common');
            $table->add_field('requiredpoints', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('criteria',       XMLDB_TYPE_TEXT,    null,  null, null);
            $table->add_field('timecreated',    XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_index('category_idx', XMLDB_INDEX_NOTUNIQUE, ['category']);

            $dbman->create_table($table);
        }

        // 4. local_mdf_user_badges — earned badges.
        $table = new xmldb_table('local_mdf_user_badges');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('userid',   XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('badgeid',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('earnedat', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_key('badgeid_fk', XMLDB_KEY_FOREIGN, ['badgeid'], 'local_mdf_badges', ['id']);
            $table->add_index('user_badge_unique', XMLDB_INDEX_UNIQUE, ['userid', 'badgeid']);

            $dbman->create_table($table);
        }

        // 5. local_mdf_challenges — challenge definitions.
        $table = new xmldb_table('local_mdf_challenges');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',           XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('title',        XMLDB_TYPE_CHAR,   '255', null, XMLDB_NOTNULL);
            $table->add_field('description',  XMLDB_TYPE_TEXT,    null,  null, null);
            $table->add_field('type',         XMLDB_TYPE_CHAR,   '50',  null, XMLDB_NOTNULL);
            $table->add_field('period',       XMLDB_TYPE_CHAR,   '20',  null, XMLDB_NOTNULL, null, 'daily');
            $table->add_field('targetvalue',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '1');
            $table->add_field('rewardpoints', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '10');
            $table->add_field('startdate',    XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('enddate',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timecreated',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_index('type_idx', XMLDB_INDEX_NOTUNIQUE, ['type']);
            $table->add_index('period_idx', XMLDB_INDEX_NOTUNIQUE, ['period']);
            $table->add_index('dates_idx', XMLDB_INDEX_NOTUNIQUE, ['startdate', 'enddate']);

            $dbman->create_table($table);
        }

        // 6. local_mdf_user_challenges — user challenge progress.
        $table = new xmldb_table('local_mdf_user_challenges');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',           XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('userid',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('challengeid',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('currentvalue', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('status',       XMLDB_TYPE_CHAR,   '20', null, XMLDB_NOTNULL, null, 'active');
            $table->add_field('claimedat',    XMLDB_TYPE_INTEGER, '10', null, null);
            $table->add_field('timecreated',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timemodified', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_key('challengeid_fk', XMLDB_KEY_FOREIGN, ['challengeid'], 'local_mdf_challenges', ['id']);
            $table->add_index('user_challenge_unique', XMLDB_INDEX_UNIQUE, ['userid', 'challengeid']);
            $table->add_index('status_idx', XMLDB_INDEX_NOTUNIQUE, ['status']);

            $dbman->create_table($table);
        }

        // ─── SOCIAL LEARNING TABLES ──────────────────────────────────

        // 7. local_mdf_study_groups
        $table = new xmldb_table('local_mdf_study_groups');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',          XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('name',        XMLDB_TYPE_CHAR,   '255', null, XMLDB_NOTNULL);
            $table->add_field('description', XMLDB_TYPE_TEXT,    null,  null, null);
            $table->add_field('courseid',    XMLDB_TYPE_INTEGER, '10', null, null);
            $table->add_field('createdby',   XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('imageurl',    XMLDB_TYPE_CHAR,   '512', null, null);
            $table->add_field('ispublic',    XMLDB_TYPE_INTEGER, '1',  null, XMLDB_NOTNULL, null, '1');
            $table->add_field('maxmembers',  XMLDB_TYPE_INTEGER, '5',  null, XMLDB_NOTNULL, null, '30');
            $table->add_field('timecreated', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timemodified', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('createdby_fk', XMLDB_KEY_FOREIGN, ['createdby'], 'user', ['id']);
            $table->add_index('courseid_idx', XMLDB_INDEX_NOTUNIQUE, ['courseid']);

            $dbman->create_table($table);
        }

        // 8. local_mdf_group_members
        $table = new xmldb_table('local_mdf_group_members');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',         XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('groupid',    XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('userid',     XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('role',       XMLDB_TYPE_CHAR,   '20', null, XMLDB_NOTNULL, null, 'member');
            $table->add_field('timejoined', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('groupid_fk', XMLDB_KEY_FOREIGN, ['groupid'], 'local_mdf_study_groups', ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('group_user_unique', XMLDB_INDEX_UNIQUE, ['groupid', 'userid']);

            $dbman->create_table($table);
        }

        // 9. local_mdf_study_notes
        $table = new xmldb_table('local_mdf_study_notes');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',           XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('title',        XMLDB_TYPE_CHAR,   '255', null, XMLDB_NOTNULL);
            $table->add_field('content',      XMLDB_TYPE_TEXT,    null,  null, XMLDB_NOTNULL);
            $table->add_field('userid',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('courseid',     XMLDB_TYPE_INTEGER, '10', null, null);
            $table->add_field('groupid',      XMLDB_TYPE_INTEGER, '10', null, null);
            $table->add_field('visibility',   XMLDB_TYPE_CHAR,   '20', null, XMLDB_NOTNULL, null, 'public');
            $table->add_field('tags',         XMLDB_TYPE_TEXT,    null,  null, null);
            $table->add_field('timecreated',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timemodified', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('courseid_idx', XMLDB_INDEX_NOTUNIQUE, ['courseid']);
            $table->add_index('groupid_idx', XMLDB_INDEX_NOTUNIQUE, ['groupid']);
            $table->add_index('visibility_idx', XMLDB_INDEX_NOTUNIQUE, ['visibility']);

            $dbman->create_table($table);
        }

        // 10. local_mdf_note_likes
        $table = new xmldb_table('local_mdf_note_likes');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',          XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('noteid',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('userid',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timecreated', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('noteid_fk', XMLDB_KEY_FOREIGN, ['noteid'], 'local_mdf_study_notes', ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('note_user_unique', XMLDB_INDEX_UNIQUE, ['noteid', 'userid']);

            $dbman->create_table($table);
        }

        // 11. local_mdf_note_bookmarks
        $table = new xmldb_table('local_mdf_note_bookmarks');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',          XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('noteid',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('userid',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timecreated', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('noteid_fk', XMLDB_KEY_FOREIGN, ['noteid'], 'local_mdf_study_notes', ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('note_user_unique', XMLDB_INDEX_UNIQUE, ['noteid', 'userid']);

            $dbman->create_table($table);
        }

        // 12. local_mdf_note_comments
        $table = new xmldb_table('local_mdf_note_comments');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',          XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('noteid',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('userid',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('content',     XMLDB_TYPE_TEXT,    null,  null, XMLDB_NOTNULL);
            $table->add_field('timecreated', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('noteid_fk', XMLDB_KEY_FOREIGN, ['noteid'], 'local_mdf_study_notes', ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('noteid_idx', XMLDB_INDEX_NOTUNIQUE, ['noteid']);

            $dbman->create_table($table);
        }

        // 13. local_mdf_collab_sessions
        $table = new xmldb_table('local_mdf_collab_sessions');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',              XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('title',           XMLDB_TYPE_CHAR,   '255', null, XMLDB_NOTNULL);
            $table->add_field('description',     XMLDB_TYPE_TEXT,    null,  null, null);
            $table->add_field('groupid',         XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('createdby',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('starttime',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('endtime',         XMLDB_TYPE_INTEGER, '10', null, null);
            $table->add_field('status',          XMLDB_TYPE_CHAR,   '20', null, XMLDB_NOTNULL, null, 'scheduled');
            $table->add_field('maxparticipants', XMLDB_TYPE_INTEGER, '5',  null, XMLDB_NOTNULL, null, '20');
            $table->add_field('topic',           XMLDB_TYPE_CHAR,   '255', null, null);
            $table->add_field('timecreated',     XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('groupid_fk', XMLDB_KEY_FOREIGN, ['groupid'], 'local_mdf_study_groups', ['id']);
            $table->add_key('createdby_fk', XMLDB_KEY_FOREIGN, ['createdby'], 'user', ['id']);
            $table->add_index('status_idx', XMLDB_INDEX_NOTUNIQUE, ['status']);
            $table->add_index('starttime_idx', XMLDB_INDEX_NOTUNIQUE, ['starttime']);

            $dbman->create_table($table);
        }

        // 14. local_mdf_session_participants
        $table = new xmldb_table('local_mdf_session_participants');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',         XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('sessionid',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('userid',     XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timejoined', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('isactive',   XMLDB_TYPE_INTEGER, '1',  null, XMLDB_NOTNULL, null, '1');

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('sessionid_fk', XMLDB_KEY_FOREIGN, ['sessionid'], 'local_mdf_collab_sessions', ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('session_user_unique', XMLDB_INDEX_UNIQUE, ['sessionid', 'userid']);

            $dbman->create_table($table);
        }

        // 15. local_mdf_session_notes
        $table = new xmldb_table('local_mdf_session_notes');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',          XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('sessionid',   XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('userid',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('content',     XMLDB_TYPE_TEXT,    null,  null, XMLDB_NOTNULL);
            $table->add_field('timecreated', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('sessionid_fk', XMLDB_KEY_FOREIGN, ['sessionid'], 'local_mdf_collab_sessions', ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('sessionid_idx', XMLDB_INDEX_NOTUNIQUE, ['sessionid']);

            $dbman->create_table($table);
        }

        // ─── Seed default badges and challenges ──────────────────────
        // Only insert if table is empty (fresh install or first upgrade).
        if (!$DB->record_exists('local_mdf_badges', [])) {
            $now = time();
            $badges = [
                ['name' => 'First Steps',      'description' => 'Enrol in your first course',             'iconname' => 'school',            'category' => 'courses',      'rarity' => 'common',    'requiredpoints' => 0,    'criteria' => 'Enroll in 1 course',          'timecreated' => $now],
                ['name' => 'Course Explorer',   'description' => 'Enrol in 5 courses',                    'iconname' => 'explore',           'category' => 'courses',      'rarity' => 'uncommon',  'requiredpoints' => 50,   'criteria' => 'Enroll in 5 courses',         'timecreated' => $now],
                ['name' => 'Scholar',           'description' => 'Complete your first course',             'iconname' => 'workspace_premium', 'category' => 'courses',      'rarity' => 'uncommon',  'requiredpoints' => 100,  'criteria' => 'Complete 1 course',           'timecreated' => $now],
                ['name' => 'Quiz Whiz',         'description' => 'Complete 10 quizzes',                    'iconname' => 'quiz',              'category' => 'quizzes',      'rarity' => 'uncommon',  'requiredpoints' => 100,  'criteria' => 'Complete 10 quizzes',         'timecreated' => $now],
                ['name' => 'Perfect Score',     'description' => 'Score 100% on any quiz',                 'iconname' => 'military_tech',     'category' => 'quizzes',      'rarity' => 'rare',      'requiredpoints' => 200,  'criteria' => 'Score 100% on a quiz',        'timecreated' => $now],
                ['name' => 'Diligent Student',  'description' => 'Submit 10 assignments',                  'iconname' => 'assignment_turned_in','category' => 'assignments', 'rarity' => 'uncommon',  'requiredpoints' => 100,  'criteria' => 'Submit 10 assignments',       'timecreated' => $now],
                ['name' => 'Social Butterfly',  'description' => 'Create 5 forum posts',                   'iconname' => 'forum',             'category' => 'social',       'rarity' => 'common',    'requiredpoints' => 25,   'criteria' => 'Create 5 forum posts',        'timecreated' => $now],
                ['name' => 'Team Player',       'description' => 'Join 3 study groups',                    'iconname' => 'groups',            'category' => 'social',       'rarity' => 'uncommon',  'requiredpoints' => 50,   'criteria' => 'Join 3 study groups',         'timecreated' => $now],
                ['name' => 'Note Taker',        'description' => 'Create 10 study notes',                  'iconname' => 'edit_note',         'category' => 'social',       'rarity' => 'uncommon',  'requiredpoints' => 75,   'criteria' => 'Create 10 study notes',       'timecreated' => $now],
                ['name' => 'Streak Master',     'description' => 'Maintain a 7-day login streak',          'iconname' => 'local_fire_department','category'=>'streaks',      'rarity' => 'rare',      'requiredpoints' => 200,  'criteria' => '7-day streak',                'timecreated' => $now],
                ['name' => 'Unstoppable',       'description' => 'Maintain a 30-day login streak',         'iconname' => 'whatshot',          'category' => 'streaks',      'rarity' => 'epic',      'requiredpoints' => 500,  'criteria' => '30-day streak',               'timecreated' => $now],
                ['name' => 'Knowledge Guru',    'description' => 'Earn 1000 total points',                 'iconname' => 'psychology',        'category' => 'general',      'rarity' => 'rare',      'requiredpoints' => 1000, 'criteria' => 'Earn 1000 points',            'timecreated' => $now],
                ['name' => 'Legend',             'description' => 'Earn 5000 total points',                 'iconname' => 'star',              'category' => 'general',      'rarity' => 'legendary', 'requiredpoints' => 5000, 'criteria' => 'Earn 5000 points',            'timecreated' => $now],
                ['name' => 'Peer Mentor',       'description' => 'Complete 5 peer reviews',                'iconname' => 'rate_review',       'category' => 'social',       'rarity' => 'rare',      'requiredpoints' => 150,  'criteria' => 'Complete 5 peer reviews',     'timecreated' => $now],
                ['name' => 'Rising Star',       'description' => 'Reach level 5',                          'iconname' => 'trending_up',       'category' => 'general',      'rarity' => 'uncommon',  'requiredpoints' => 0,    'criteria' => 'Reach level 5',               'timecreated' => $now],
            ];
            foreach ($badges as $badge) {
                $DB->insert_record('local_mdf_badges', (object) $badge);
            }
        }

        // Seed default daily/weekly challenges if none exist.
        if (!$DB->record_exists('local_mdf_challenges', [])) {
            $now = time();
            $day_start = mktime(0, 0, 0);
            $day_end   = $day_start + DAYSECS - 1;
            $week_start = strtotime('monday this week');
            $week_end   = $week_start + (7 * DAYSECS) - 1;

            $challenges = [
                ['title' => 'Daily Login',         'description' => 'Log in today',                       'type' => 'login_streak',    'period' => 'daily',  'targetvalue' => 1, 'rewardpoints' => 5,  'startdate' => $day_start,  'enddate' => $day_end,   'timecreated' => $now],
                ['title' => 'Complete a Module',    'description' => 'Complete any course module today',    'type' => 'module_complete', 'period' => 'daily',  'targetvalue' => 1, 'rewardpoints' => 10, 'startdate' => $day_start,  'enddate' => $day_end,   'timecreated' => $now],
                ['title' => 'Forum Contributor',    'description' => 'Create a forum post today',           'type' => 'forum_post',      'period' => 'daily',  'targetvalue' => 1, 'rewardpoints' => 10, 'startdate' => $day_start,  'enddate' => $day_end,   'timecreated' => $now],
                ['title' => 'Weekly Scholar',       'description' => 'Complete 5 modules this week',        'type' => 'module_complete', 'period' => 'weekly', 'targetvalue' => 5, 'rewardpoints' => 50, 'startdate' => $week_start, 'enddate' => $week_end,  'timecreated' => $now],
                ['title' => 'Quiz Champion',        'description' => 'Complete 3 quizzes this week',        'type' => 'quiz_score',      'period' => 'weekly', 'targetvalue' => 3, 'rewardpoints' => 40, 'startdate' => $week_start, 'enddate' => $week_end,  'timecreated' => $now],
                ['title' => 'Social Learner',       'description' => 'Create 3 study notes this week',      'type' => 'note_create',     'period' => 'weekly', 'targetvalue' => 3, 'rewardpoints' => 30, 'startdate' => $week_start, 'enddate' => $week_end,  'timecreated' => $now],
                ['title' => 'Course Enrollee',      'description' => 'Enrol in a new course this week',     'type' => 'course_enroll',   'period' => 'weekly', 'targetvalue' => 1, 'rewardpoints' => 15, 'startdate' => $week_start, 'enddate' => $week_end,  'timecreated' => $now],
            ];
            foreach ($challenges as $ch) {
                $DB->insert_record('local_mdf_challenges', (object) $ch);
            }
        }

        upgrade_plugin_savepoint(true, 2026030200, 'local', 'mdf_api');
    }

    // =====================================================================
    // v2.0.1 — Fix FCM token index (CHAR > 255 cannot be indexed).
    // Change token to TEXT, add tokenhash CHAR(64) with unique index.
    // =====================================================================
    if ($oldversion < 2026030201) {
        $table = new xmldb_table('local_mdf_fcm_tokens');

        // 1. Drop the old token_unique index if it exists.
        $index = new xmldb_index('token_unique', XMLDB_INDEX_UNIQUE, ['token']);
        if ($dbman->index_exists($table, $index)) {
            $dbman->drop_index($table, $index);
        }

        // 2. Change token field from CHAR(512) to TEXT.
        $field = new xmldb_field('token', XMLDB_TYPE_TEXT, null, null, XMLDB_NOTNULL, null, null, 'userid');
        $dbman->change_field_type($table, $field);

        // 3. Add tokenhash field CHAR(64) if it doesn't exist.
        $field = new xmldb_field('tokenhash', XMLDB_TYPE_CHAR, '64', null, XMLDB_NOTNULL, null, '', 'token');
        if (!$dbman->field_exists($table, $field)) {
            $dbman->add_field($table, $field);
        }

        // 4. Backfill tokenhash for any existing records.
        $records = $DB->get_records('local_mdf_fcm_tokens');
        foreach ($records as $rec) {
            $rec->tokenhash = hash('sha256', $rec->token);
            $DB->update_record('local_mdf_fcm_tokens', $rec);
        }

        // 5. Add unique index on tokenhash.
        $index = new xmldb_index('tokenhash_unique', XMLDB_INDEX_UNIQUE, ['tokenhash']);
        if (!$dbman->index_exists($table, $index)) {
            $dbman->add_index($table, $index);
        }

        upgrade_plugin_savepoint(true, 2026030201, 'local', 'mdf_api');
    }

    // =====================================================================
    // v2.1.0 — Course Visibility + Cohort Management.
    // =====================================================================
    if ($oldversion < 2026030202) {

        // local_mdf_course_visibility — per-course visibility overrides.
        $table = new xmldb_table('local_mdf_course_visibility');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',           XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('courseid',     XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('targettype',   XMLDB_TYPE_CHAR,   '10', null, XMLDB_NOTNULL);
            $table->add_field('targetid',     XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('hidden',       XMLDB_TYPE_INTEGER, '1',  null, XMLDB_NOTNULL, null, '1');
            $table->add_field('timecreated',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timemodified', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);

            $table->add_index('courseid_idx',         XMLDB_INDEX_NOTUNIQUE, ['courseid']);
            $table->add_index('target_idx',           XMLDB_INDEX_NOTUNIQUE, ['targettype', 'targetid']);
            $table->add_index('course_target_unique', XMLDB_INDEX_UNIQUE,    ['courseid', 'targettype', 'targetid']);

            $dbman->create_table($table);
        }

        upgrade_plugin_savepoint(true, 2026030202, 'local', 'mdf_api');
    }

    // =====================================================================
    // v2.1.1 — Service/core function sync + API compatibility fixes.
    // =====================================================================
    if ($oldversion < 2026030300) {
        upgrade_plugin_savepoint(true, 2026030300, 'local', 'mdf_api');
    }

    // =====================================================================
    // v2.2.0 — AI Management + Enhanced Cohort/Course Management.
    // =====================================================================
    if ($oldversion < 2026030400) {

        // 1. local_mdf_ai_config — AI provider configuration.
        $table = new xmldb_table('local_mdf_ai_config');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',           XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('provider',     XMLDB_TYPE_CHAR,   '50', null, XMLDB_NOTNULL);
            $table->add_field('apikey',       XMLDB_TYPE_TEXT,    null, null, XMLDB_NOTNULL);
            $table->add_field('model',        XMLDB_TYPE_CHAR,  '100', null, null);
            $table->add_field('systemprompt', XMLDB_TYPE_TEXT,    null, null, null);
            $table->add_field('maxtokens',    XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '1024');
            $table->add_field('temperature',  XMLDB_TYPE_NUMBER,  '4',  null, XMLDB_NOTNULL, null, '0.70');
            $table->add_field('enabled',      XMLDB_TYPE_INTEGER, '1',  null, XMLDB_NOTNULL, null, '1');
            $table->add_field('timecreated',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('timemodified', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_index('provider_unique', XMLDB_INDEX_UNIQUE, ['provider']);

            $dbman->create_table($table);
        }

        // 2. local_mdf_ai_messages — chat history.
        $table = new xmldb_table('local_mdf_ai_messages');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',          XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('userid',      XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);
            $table->add_field('role',        XMLDB_TYPE_CHAR,   '20', null, XMLDB_NOTNULL);
            $table->add_field('content',     XMLDB_TYPE_TEXT,    null, null, XMLDB_NOTNULL);
            $table->add_field('provider',    XMLDB_TYPE_CHAR,   '50', null, XMLDB_NOTNULL, null, 'local');
            $table->add_field('tokensused',  XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('timecreated', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_key('userid_fk', XMLDB_KEY_FOREIGN, ['userid'], 'user', ['id']);
            $table->add_index('userid_time_idx', XMLDB_INDEX_NOTUNIQUE, ['userid', 'timecreated']);
            $table->add_index('provider_idx', XMLDB_INDEX_NOTUNIQUE, ['provider']);

            $dbman->create_table($table);
        }

        // 3. local_mdf_ai_limits — per-user message limits.
        $table = new xmldb_table('local_mdf_ai_limits');
        if (!$dbman->table_exists($table)) {
            $table->add_field('id',           XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, XMLDB_SEQUENCE);
            $table->add_field('userid',       XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('dailylimit',   XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '50');
            $table->add_field('monthlylimit', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '1000');
            $table->add_field('dailycount',   XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('monthlycount', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('lastreset',    XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL, null, '0');
            $table->add_field('timemodified', XMLDB_TYPE_INTEGER, '10', null, XMLDB_NOTNULL);

            $table->add_key('primary', XMLDB_KEY_PRIMARY, ['id']);
            $table->add_index('userid_unique', XMLDB_INDEX_UNIQUE, ['userid']);

            $dbman->create_table($table);
        }

        // Seed default AI limits (userid=0 = system defaults).
        if (!$DB->record_exists('local_mdf_ai_limits', ['userid' => 0])) {
            $DB->insert_record('local_mdf_ai_limits', (object)[
                'userid'       => 0,
                'dailylimit'   => 50,
                'monthlylimit' => 1000,
                'dailycount'   => 0,
                'monthlycount' => 0,
                'lastreset'    => time(),
                'timemodified' => time(),
            ]);
        }

        upgrade_plugin_savepoint(true, 2026030400, 'local', 'mdf_api');
    }

    return true;
}
