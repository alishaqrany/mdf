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

namespace local_mdf_api;

defined('MOODLE_INTERNAL') || die();

/**
 * Gamification helper — shared logic for awarding points, checking badges,
 * updating challenges, and managing streaks.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class gamification_helper {

    /** Level thresholds: level => cumulative points required. */
    private const LEVEL_THRESHOLDS = [
        1 => 0, 2 => 100, 3 => 250, 4 => 500, 5 => 1000,
        6 => 1750, 7 => 2750, 8 => 4000, 9 => 5500, 10 => 7500,
        11 => 10000, 12 => 13000, 13 => 16500, 14 => 20500, 15 => 25000,
        16 => 30000, 17 => 36000, 18 => 43000, 19 => 51000, 20 => 60000,
    ];

    /**
     * Award points to a user and update their profile.
     *
     * @param int    $userid
     * @param int    $points
     * @param string $action      One of the PointAction enum values (snake_case).
     * @param string $description Human-readable description.
     * @param int|null $referenceid Optional related object ID.
     * @return void
     */
    public static function award_points(int $userid, int $points, string $action,
                                         string $description = '', ?int $referenceid = null): void {
        global $DB;

        if ($points <= 0) {
            return;
        }

        // Check gamification is enabled.
        if (!get_config('local_mdf_api', 'enable_gamification')) {
            return;
        }

        $now = time();

        // 1. Insert transaction record.
        $tx = new \stdClass();
        $tx->userid      = $userid;
        $tx->points      = $points;
        $tx->action      = $action;
        $tx->description = $description;
        $tx->referenceid = $referenceid;
        $tx->timecreated = $now;
        $DB->insert_record('local_mdf_point_transactions', $tx);

        // 2. Get or create user points profile.
        $profile = $DB->get_record('local_mdf_user_points', ['userid' => $userid]);
        if (!$profile) {
            $profile = new \stdClass();
            $profile->userid            = $userid;
            $profile->totalpoints       = 0;
            $profile->level             = 1;
            $profile->currentlevelpoints = 0;
            $profile->nextlevelpoints   = 100;
            $profile->currentstreak     = 0;
            $profile->longeststreak     = 0;
            $profile->lastactivitydate  = null;
            $profile->timecreated       = $now;
            $profile->timemodified      = $now;
            $profile->id = $DB->insert_record('local_mdf_user_points', $profile);
        }

        // 3. Update totals.
        $profile->totalpoints += $points;
        $profile->lastactivitydate = $now;
        $profile->timemodified = $now;

        // 4. Recalculate level.
        self::recalculate_level($profile);

        $DB->update_record('local_mdf_user_points', $profile);

        // 5. Check if any badges should be awarded.
        self::check_badges($userid, $profile);

        // 6. Update active challenges matching this action.
        self::update_challenges($userid, $action);
    }

    /**
     * Recalculate level based on total points.
     *
     * @param \stdClass $profile The user_points record (modified in-place).
     */
    public static function recalculate_level(\stdClass &$profile): void {
        $total = $profile->totalpoints;
        $level = 1;
        $thresholds = self::LEVEL_THRESHOLDS;
        $maxLevel = max(array_keys($thresholds));

        foreach ($thresholds as $lvl => $required) {
            if ($total >= $required) {
                $level = $lvl;
            }
        }

        // Handle levels beyond defined thresholds.
        if ($level >= $maxLevel && $total > $thresholds[$maxLevel]) {
            $extra = $total - $thresholds[$maxLevel];
            $level = $maxLevel + intdiv($extra, 10000);
        }

        $profile->level = $level;

        // Current level points and next level.
        $currentThreshold = $thresholds[$level] ?? ($thresholds[$maxLevel] + ($level - $maxLevel) * 10000);
        $nextLevel = $level + 1;
        $nextThreshold = $thresholds[$nextLevel] ?? ($currentThreshold + 10000);

        $profile->currentlevelpoints = $total - $currentThreshold;
        $profile->nextlevelpoints    = $nextThreshold - $currentThreshold;
    }

    /**
     * Update the user's daily login streak.
     *
     * @param int $userid
     * @return array ['streak' => int, 'bonus' => int, 'points_awarded' => int]
     */
    public static function record_daily_login(int $userid): array {
        global $DB;

        $now   = time();
        $today = mktime(0, 0, 0);
        $yesterday = $today - DAYSECS;

        $profile = $DB->get_record('local_mdf_user_points', ['userid' => $userid]);
        if (!$profile) {
            // Create profile first.
            self::award_points($userid, 5, 'daily_login', 'Daily login bonus');
            $profile = $DB->get_record('local_mdf_user_points', ['userid' => $userid]);
            return ['streak' => 1, 'bonus' => 5, 'points_awarded' => 5];
        }

        $lastDate = $profile->lastactivitydate ? mktime(0, 0, 0,
            date('m', $profile->lastactivitydate),
            date('d', $profile->lastactivitydate),
            date('Y', $profile->lastactivitydate)
        ) : 0;

        // Already logged in today.
        if ($lastDate >= $today) {
            return ['streak' => (int)$profile->currentstreak, 'bonus' => 0, 'points_awarded' => 0];
        }

        // Consecutive day.
        if ($lastDate >= $yesterday) {
            $profile->currentstreak++;
        } else {
            $profile->currentstreak = 1;
        }

        if ($profile->currentstreak > $profile->longeststreak) {
            $profile->longeststreak = $profile->currentstreak;
        }

        $profile->lastactivitydate = $now;
        $profile->timemodified = $now;
        $DB->update_record('local_mdf_user_points', $profile);

        // Award base login points.
        $points = 5;

        // Streak bonus: every 7 days give extra.
        $bonus = 0;
        if ($profile->currentstreak % 7 === 0) {
            $bonus = min(50, (int)($profile->currentstreak / 7) * 10);
        }

        self::award_points($userid, $points, 'daily_login', 'Daily login bonus');
        if ($bonus > 0) {
            self::award_points($userid, $bonus, 'streak_bonus',
                "Streak bonus ({$profile->currentstreak} day streak)");
        }

        return [
            'streak'         => (int)$profile->currentstreak,
            'bonus'          => $bonus,
            'points_awarded' => $points + $bonus,
        ];
    }

    /**
     * Check and award badges based on current user profile.
     *
     * @param int       $userid
     * @param \stdClass $profile
     */
    public static function check_badges(int $userid, \stdClass $profile): void {
        global $DB;

        $allBadges = $DB->get_records('local_mdf_badges');
        $earnedIds = $DB->get_fieldset_select('local_mdf_user_badges', 'badgeid',
            'userid = ?', [$userid]);

        foreach ($allBadges as $badge) {
            if (in_array($badge->id, $earnedIds)) {
                continue;
            }

            $earned = false;

            // Points-based badges.
            if ($badge->requiredpoints > 0 && $profile->totalpoints >= $badge->requiredpoints) {
                $earned = true;
            }

            // Criteria-based badges (simple string matching).
            if (!$earned && !empty($badge->criteria)) {
                $earned = self::evaluate_badge_criteria($userid, $badge->criteria, $profile);
            }

            if ($earned) {
                $ub = new \stdClass();
                $ub->userid  = $userid;
                $ub->badgeid = $badge->id;
                $ub->earnedat = time();
                try {
                    $DB->insert_record('local_mdf_user_badges', $ub);
                    // Award bonus points for earning a badge.
                    self::award_points($userid, 25, 'badge_earned',
                        "Earned badge: {$badge->name}", $badge->id);
                } catch (\dml_write_exception $e) {
                    // Duplicate — ignore.
                }
            }
        }
    }

    /**
     * Evaluate a badge criteria string against user data.
     *
     * Simple criteria format examples:
     *   "Enroll in 1 course"
     *   "Complete 1 course"
     *   "7-day streak"
     *   "30-day streak"
     *   "Reach level 5"
     *
     * @param int       $userid
     * @param string    $criteria
     * @param \stdClass $profile
     * @return bool
     */
    private static function evaluate_badge_criteria(int $userid, string $criteria, \stdClass $profile): bool {
        global $DB;

        $criteria = strtolower(trim($criteria));

        // Streak checks.
        if (preg_match('/(\d+)-day streak/', $criteria, $m)) {
            return $profile->currentstreak >= (int)$m[1];
        }

        // Level checks.
        if (preg_match('/reach level (\d+)/', $criteria, $m)) {
            return $profile->level >= (int)$m[1];
        }

        // Count-based checks from transaction history.
        $actionMap = [
            'enroll in'         => 'course_enroll',
            'complete'          => 'module_complete',
            'submit'            => 'assignment_submit',
            'forum post'        => 'forum_post',
            'study note'        => 'note_create',
            'peer review'       => 'review_complete',
            'quiz'              => 'quiz_complete',
        ];

        foreach ($actionMap as $keyword => $action) {
            if (strpos($criteria, $keyword) !== false) {
                if (preg_match('/(\d+)/', $criteria, $m)) {
                    $target = (int)$m[1];
                    // Special: "complete 1 course" means course_completed.
                    if ($keyword === 'complete' && strpos($criteria, 'course') !== false) {
                        $count = $DB->count_records_select('course_completions',
                            'userid = ?', [$userid]);
                    } else if ($keyword === 'enroll in') {
                        $count = $DB->count_records_select('local_mdf_point_transactions',
                            "userid = ? AND action = ?", [$userid, $action]);
                    } else {
                        $count = $DB->count_records_select('local_mdf_point_transactions',
                            "userid = ? AND action = ?", [$userid, $action]);
                    }
                    return $count >= $target;
                }
            }
        }

        // "join*study group*" counts.
        if (strpos($criteria, 'join') !== false && strpos($criteria, 'group') !== false) {
            if (preg_match('/(\d+)/', $criteria, $m)) {
                $count = $DB->count_records('local_mdf_group_members', ['userid' => $userid]);
                return $count >= (int)$m[1];
            }
        }

        return false;
    }

    /**
     * Update active challenges that match a given action.
     *
     * @param int    $userid
     * @param string $action
     */
    public static function update_challenges(int $userid, string $action): void {
        global $DB;

        $now = time();

        // Map point actions to challenge types.
        $challengeTypeMap = [
            'course_enroll'      => 'course_enroll',
            'module_complete'    => 'module_complete',
            'quiz_complete'      => 'quiz_score',
            'assignment_submit'  => 'module_complete',
            'forum_post'         => 'forum_post',
            'note_create'        => 'note_create',
            'daily_login'        => 'login_streak',
        ];

        $challengeType = $challengeTypeMap[$action] ?? null;
        if (!$challengeType) {
            return;
        }

        // Get active challenges of this type that haven't expired.
        $sql = "SELECT c.*, uc.id as ucid, uc.currentvalue, uc.status as ucstatus
                FROM {local_mdf_challenges} c
                LEFT JOIN {local_mdf_user_challenges} uc
                    ON uc.challengeid = c.id AND uc.userid = :userid
                WHERE c.type = :type
                  AND c.startdate <= :now1
                  AND c.enddate >= :now2";

        $challenges = $DB->get_records_sql($sql, [
            'userid' => $userid,
            'type'   => $challengeType,
            'now1'   => $now,
            'now2'   => $now,
        ]);

        foreach ($challenges as $ch) {
            if (!empty($ch->ucid)) {
                // Already tracking — update if still active.
                if ($ch->ucstatus === 'active') {
                    $newVal = (int)$ch->currentvalue + 1;
                    $status = ($newVal >= (int)$ch->targetvalue) ? 'completed' : 'active';
                    $DB->update_record('local_mdf_user_challenges', (object)[
                        'id'           => $ch->ucid,
                        'currentvalue' => $newVal,
                        'status'       => $status,
                        'timemodified' => $now,
                    ]);
                }
            } else {
                // Start tracking this challenge.
                $status = (1 >= (int)$ch->targetvalue) ? 'completed' : 'active';
                $DB->insert_record('local_mdf_user_challenges', (object)[
                    'userid'       => $userid,
                    'challengeid'  => $ch->id,
                    'currentvalue' => 1,
                    'status'       => $status,
                    'claimedat'    => null,
                    'timecreated'  => $now,
                    'timemodified' => $now,
                ]);
            }
        }
    }

    /**
     * Get the full user points profile with rank.
     *
     * @param int $userid
     * @return array
     */
    public static function get_user_profile(int $userid): array {
        global $DB;

        $profile = $DB->get_record('local_mdf_user_points', ['userid' => $userid]);
        if (!$profile) {
            // Create default profile.
            $now = time();
            $profile = (object)[
                'userid'            => $userid,
                'totalpoints'       => 0,
                'level'             => 1,
                'currentlevelpoints' => 0,
                'nextlevelpoints'   => 100,
                'currentstreak'     => 0,
                'longeststreak'     => 0,
                'lastactivitydate'  => null,
                'timecreated'       => $now,
                'timemodified'      => $now,
            ];
            $profile->id = $DB->insert_record('local_mdf_user_points', $profile);
        }

        // Calculate rank.
        $rank = $DB->count_records_select('local_mdf_user_points',
            'totalpoints > ?', [$profile->totalpoints]) + 1;

        $totalUsers = $DB->count_records('local_mdf_user_points');

        // Get user display info.
        $user = $DB->get_record('user', ['id' => $userid], 'id, firstname, lastname, picture, imagealt, email');
        $fullname = $user ? trim($user->firstname . ' ' . $user->lastname) : '';

        $profileimageurl = '';
        if ($user) {
            $userpicture = new \user_picture($user);
            $userpicture->size = 100;
            // We'll just provide a generic URL pattern that works with web service tokens.
            $profileimageurl = '';
        }

        return [
            'userid'            => (int)$profile->userid,
            'fullname'          => $fullname,
            'profileimageurl'   => $profileimageurl,
            'totalpoints'       => (int)$profile->totalpoints,
            'level'             => (int)$profile->level,
            'currentlevelpoints' => (int)$profile->currentlevelpoints,
            'nextlevelpoints'   => (int)$profile->nextlevelpoints,
            'currentstreak'     => (int)$profile->currentstreak,
            'longeststreak'     => (int)$profile->longeststreak,
            'lastactivitydate'  => (int)($profile->lastactivitydate ?? 0),
            'rank'              => (int)$rank,
            'totalusers'        => (int)$totalUsers,
        ];
    }
}
