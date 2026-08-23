package com.kreativekoala.pdfgenius.tools

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.util.UUID

/**
 * Shared "copy a picked SAF Uri into app-private storage" helper, factored out of
 * DocumentListViewModel.importPdf so every tool screen (which each need to pick one
 * or more source PDFs before running an operation) can reuse the exact same pattern
 * instead of re-inventing it per tool.
 */
object PdfFileImporter {

    fun copyUriToWorkingFile(context: Context, uri: Uri, subDir: String = "tool_inputs"): File? {
        val dir = File(context.filesDir, subDir).apply { mkdirs() }
        val displayName = queryDisplayName(context, uri) ?: "Input_${UUID.randomUUID().toString().take(6)}.pdf"
        var destFile = File(dir, displayName)
        if (destFile.exists()) {
            destFile = File(dir, "${destFile.nameWithoutExtension}_${UUID.randomUUID().toString().take(6)}.pdf")
        }
        return try {
            context.contentResolver.openInputStream(uri)?.use { input ->
                destFile.outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            destFile
        } catch (e: Exception) {
            null
        }
    }

    private fun queryDisplayName(context: Context, uri: Uri): String? {
        val cursor = context.contentResolver.query(uri, null, null, null, null) ?: return null
        cursor.use {
            val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (nameIndex >= 0 && it.moveToFirst()) return it.getString(nameIndex)
        }
        return null
    }

    fun countPdfPages(file: File): Int = try {
        android.os.ParcelFileDescriptor.open(file, android.os.ParcelFileDescriptor.MODE_READ_ONLY).use { pfd ->
            android.graphics.pdf.PdfRenderer(pfd).use { renderer -> renderer.pageCount }
        }
    } catch (e: Exception) {
        0
    }
}
