package com.kreativekoala.pdfgenius.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.kreativekoala.pdfgenius.data.model.PdfDocument
import kotlinx.coroutines.flow.Flow

@Dao
interface PdfDocumentDao {

    @Query("SELECT * FROM pdf_documents ORDER BY createdAtEpochMillis DESC")
    fun observeAll(): Flow<List<PdfDocument>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(document: PdfDocument)

    @Delete
    suspend fun delete(document: PdfDocument)

    @Query("DELETE FROM pdf_documents WHERE id = :id")
    suspend fun deleteById(id: String)
}
