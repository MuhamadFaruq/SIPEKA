package com.example.sipeka

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ShortcutWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.shortcut_widget).apply {
                val shortcutPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("sipeka://widget/shortcut")
                )
                setOnClickPendingIntent(R.id.btn_widget_shortcut, shortcutPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
