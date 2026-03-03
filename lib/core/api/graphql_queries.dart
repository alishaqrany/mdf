/// Typed GraphQL query and mutation documents.
///
/// Each constant is a raw GraphQL document string that can be passed
/// to [GraphQLClient.query] or [GraphQLClient.mutate].
class GraphQLQueries {
  GraphQLQueries._();

  // ─── Site ───

  static const getSiteInfo = r'''
    query GetSiteInfo {
      siteInfo {
        siteName
        siteUrl
        username
        userId
        fullName
        userPictureUrl
        lang
        functions
      }
    }
  ''';

  // ─── Courses ───

  static const getEnrolledCourses = r'''
    query GetEnrolledCourses($userId: Int!) {
      enrolledCourses(userId: $userId) {
        id
        shortName
        fullName
        summary
        startDate
        endDate
        progress
        imageUrl
        categoryId
        categoryName
        visible
        favourite
      }
    }
  ''';

  static const getCourseContents = r'''
    query GetCourseContents($courseId: Int!) {
      courseContents(courseId: $courseId) {
        id
        name
        summary
        visible
        modules {
          id
          name
          modName
          url
          visible
          description
          contents {
            type
            filename
            fileUrl
            fileSize
            timeModified
          }
        }
      }
    }
  ''';

  static const searchCourses = r'''
    query SearchCourses($query: String!, $page: Int, $perPage: Int) {
      searchCourses(query: $query, page: $page, perPage: $perPage) {
        total
        courses {
          id
          shortName
          fullName
          summary
          imageUrl
          categoryName
          enrolledUserCount
        }
      }
    }
  ''';

  // ─── Grades ───

  static const getCourseGrades = r'''
    query GetCourseGrades($courseId: Int!, $userId: Int!) {
      courseGrades(courseId: $courseId, userId: $userId) {
        gradeItems {
          id
          itemName
          gradeRaw
          gradeMax
          gradeMin
          percentage
          feedback
        }
        courseTotal {
          gradeRaw
          gradeMax
          percentage
        }
      }
    }
  ''';

  // ─── Messaging ───

  static const getConversations = r'''
    query GetConversations($userId: Int!, $type: Int, $limit: Int, $offset: Int) {
      conversations(userId: $userId, type: $type, limit: $limit, offset: $offset) {
        id
        name
        type
        memberCount
        unreadCount
        imageUrl
        lastMessage {
          id
          text
          userIdFrom
          timeCreated
        }
        members {
          id
          fullName
          profileImageUrl
          isOnline
        }
      }
    }
  ''';

  static const sendMessage = r'''
    mutation SendMessage($conversationId: Int!, $text: String!) {
      sendMessage(conversationId: $conversationId, text: $text) {
        id
        text
        userIdFrom
        timeCreated
      }
    }
  ''';

  // ─── Calendar ───

  static const getCalendarEvents = r'''
    query GetCalendarEvents($year: Int!, $month: Int!) {
      calendarEvents(year: $year, month: $month) {
        id
        name
        description
        timeStart
        timeEnd
        eventType
        courseId
        courseName
        url
      }
    }
  ''';

  // ─── Notifications ───

  static const getNotifications = r'''
    query GetNotifications($userId: Int!, $limit: Int, $offset: Int) {
      notifications(userId: $userId, limit: $limit, offset: $offset) {
        id
        subject
        shortMessage
        fullMessage
        timeCreated
        read
        contextUrl
        component
      }
    }
  ''';

  static const markNotificationRead = r'''
    mutation MarkNotificationRead($notificationId: Int!) {
      markNotificationRead(notificationId: $notificationId) {
        success
      }
    }
  ''';

  // ─── Quizzes ───

  static const getCourseQuizzes = r'''
    query GetCourseQuizzes($courseId: Int!) {
      courseQuizzes(courseId: $courseId) {
        id
        courseId
        name
        intro
        timeOpen
        timeClose
        timeLimit
        attempts
        gradeMethod
        grade
      }
    }
  ''';

  // ─── Assignments ───

  static const getCourseAssignments = r'''
    query GetCourseAssignments($courseId: Int!) {
      courseAssignments(courseId: $courseId) {
        id
        courseId
        name
        intro
        dueDate
        allowSubmissionsFrom
        grade
        submissionStatus
      }
    }
  ''';

  // ─── Users (Admin) ───

  static const searchUsers = r'''
    query SearchUsers($query: String!, $page: Int, $perPage: Int) {
      searchUsers(query: $query, page: $page, perPage: $perPage) {
        total
        users {
          id
          username
          fullName
          email
          profileImageUrl
          lastAccess
          suspended
        }
      }
    }
  ''';

  // ─── Gamification ───

  static const getUserPoints = r'''
    query GetUserPoints($userId: Int!) {
      userPoints(userId: $userId) {
        totalXp
        level
        levelTitle
        streakDays
        rank
      }
    }
  ''';

  static const getLeaderboard = r'''
    query GetLeaderboard($period: String!, $limit: Int) {
      leaderboard(period: $period, limit: $limit) {
        entries {
          userId
          fullName
          profileImageUrl
          totalXp
          level
          rank
        }
      }
    }
  ''';
}
