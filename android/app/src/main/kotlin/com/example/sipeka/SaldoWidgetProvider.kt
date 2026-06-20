package com.example.sipeka

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SaldoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.saldo_widget).apply {
                val saldo = widgetData.getString("total_saldo", "Rp 0")
                setTextViewText(R.id.widget_saldo, saldo)

                val mainPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("sipeka://widget/home")
                )
                setOnClickPendingIntent(R.id.widget_container, mainPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
