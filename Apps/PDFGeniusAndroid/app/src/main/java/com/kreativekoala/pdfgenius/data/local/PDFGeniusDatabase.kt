package com.kreativekoala.pdfgenius.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.kreativekoala.pdfgenius.data.model.PdfDocument

@Database(entities = [PdfDocument::class], version = 1, exportSchema = false)
@TypeConverters(Converters::class)
abstract class PDFGeniusDatabase : RoomDatabase() {
    abstract fun pdfDocumentDao(): PdfDocumentDao
}
