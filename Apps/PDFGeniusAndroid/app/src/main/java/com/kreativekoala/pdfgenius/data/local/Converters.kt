package com.kreativekoala.pdfgenius.data.local

import androidx.room.TypeConverter
import com.kreativekoala.pdfgenius.data.model.SourceTool

class Converters {
    @TypeConverter
    fun fromSourceTool(value: SourceTool): String = value.name

    @TypeConverter
    fun toSourceTool(value: String): SourceTool = SourceTool.valueOf(value)
}
