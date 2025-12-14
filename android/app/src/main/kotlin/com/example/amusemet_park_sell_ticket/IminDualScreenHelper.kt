package com.example.amusemet_park_sell_ticket

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.imin.image.ILcdManager

class IminDualScreenHelper(private val context: Context) {
    
    private val lcdManager: ILcdManager by lazy {
        ILcdManager.getInstance(context)
    }

    /**
     * แสดงรูป QR บนจอลูกค้า (จอที่ 2)
     */
    fun showImageOnCustomerScreen(imageBytes: ByteArray): Boolean {
        return try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            lcdManager.sendLCDBitmap(bitmap)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    /**
     * ล้างจอลูกค้า
     */
    fun clearCustomerScreen(): Boolean {
        return try {
            lcdManager.sendLCDCommand(1) // Clear command
            lcdManager.sendLCDCommand(4) // Wake up command
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
