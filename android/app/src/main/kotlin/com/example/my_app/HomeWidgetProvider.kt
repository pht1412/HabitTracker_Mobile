package com.example.my_app  // ⚠️ Đảm bảo dòng này đúng với package của bạn

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {

                // 1. LẤY DỮ LIỆU
                val title = widgetData.getString("habit_title", "Chưa có thói quen")
                val time = widgetData.getString("habit_time", "--:--")
                // 🔥 MỚI: Lấy trạng thái check
                val isChecked = widgetData.getBoolean("is_checked", false)

                // 2. GÁN DỮ LIỆU VÀO GIAO DIỆN
                setTextViewText(R.id.habit_title, title)
                setTextViewText(R.id.habit_time, time)

                // 🔥 MỚI: Đổi background nút bấm dựa trên trạng thái check
                val backgroundRes = if (isChecked) R.drawable.btn_circle_checked else R.drawable.btn_circle_outline
                setInt(R.id.btn_check, "setBackgroundResource", backgroundRes)

                // 3. XỬ LÝ SỰ KIỆN BẤM
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    android.net.Uri.parse("homeWidget://btn_check")
                )
                setOnClickPendingIntent(R.id.btn_check, backgroundIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}