package io.rea.multilingo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Shared helpers. Flutter writes the values (see widget_sync.dart); these
 * widgets only read them, so they never need the Flutter engine to run.
 */
private fun RemoteViews.bindCommon(
    context: Context,
    data: SharedPreferences,
) {
    val mood = data.getString("mood", "happy") ?: "happy"
    val id = context.resources.getIdentifier("pip_$mood", "drawable", context.packageName)
    if (id != 0) setImageViewResource(R.id.widget_pip, id)
    setOnClickPendingIntent(
        R.id.widget_root,
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
    )
}

class StreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_streak)
            views.bindCommon(context, widgetData)
            views.setTextViewText(R.id.widget_streak_count, widgetData.getInt("streak", 0).toString())
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class GoalWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val goal = widgetData.getInt("goal_xp", 20).coerceAtLeast(1)
        val today = widgetData.getInt("today_xp", 0)
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_goal)
            views.bindCommon(context, widgetData)
            views.setProgressBar(R.id.widget_goal_bar, goal, today.coerceAtMost(goal), false)
            views.setTextViewText(R.id.widget_goal_text, "$today / $goal XP")
            views.setTextViewText(R.id.widget_message, widgetData.getString("message", "") ?: "")
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class NextLessonWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_next)
            views.bindCommon(context, widgetData)
            views.setTextViewText(R.id.widget_next_title, widgetData.getString("next_title", "") ?: "")
            views.setTextViewText(R.id.widget_next_detail, widgetData.getString("next_detail", "") ?: "")
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
