package com.kreativekoala.pdfgenius.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

/**
 * Local record of an imported or generated PDF.
 *
 * Mirrors iOS's `PDFDocumentItem` (App/Models.swift): title, on-disk file location,
 * page count, file size, and creation date. `sourceTool` is new here — it's used to
 * derive the same "Merged / Split / Compressed / Protected" badges that iOS's
 * `PDFDocumentRow.badge` computes by string-sniffing the title; we store it as a real
 * field instead of pattern-matching the title.
 */
@Entity(tableName = "pdf_documents")
data class PdfDocument(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val title: String,
    val filePath: String,
    val pageCount: Int,
    val fileSizeBytes: Long,
    val createdAtEpochMillis: Long,
    val sourceTool: SourceTool = SourceTool.IMPORTED,
)

enum class SourceTool {
    IMPORTED, MERGED, SPLIT, COMPRESSED, PASSWORD_PROTECTED, CONVERTED, SIGNED
}
