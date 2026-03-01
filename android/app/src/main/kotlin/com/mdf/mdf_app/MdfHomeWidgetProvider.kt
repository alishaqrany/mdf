package com.mdf.mdf_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Android Home Screen Widget – shows upcoming event title + course count.
 * Data is pushed from Flutter via home_widget package.
 */
class MdfHomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_mdf).apply {
                // Title
                val title = widgetData.getString("title", "MDF Learning") ?: "MDF Learning"
                setTextViewText(R.id.widget_title, title)

                // Course count
                val courseCount = widgetData.getString("course_count", "0") ?: "0"
                setTextViewText(R.id.widget_course_count, "$courseCount courses enrolled")

                // Next event
                val nextEvent = widgetData.getString("next_event", "No upcoming events") ?: "No upcoming events"
                setTextViewText(R.id.widget_next_event, nextEvent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
