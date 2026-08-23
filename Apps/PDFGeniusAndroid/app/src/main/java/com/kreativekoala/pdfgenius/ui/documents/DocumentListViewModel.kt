package com.kreativekoala.pdfgenius.ui.documents

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kreativekoala.pdfgenius.data.PdfDocumentRepository
import com.kreativekoala.pdfgenius.data.model.PdfDocument
import com.kreativekoala.pdfgenius.data.model.SourceTool
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.util.UUID
import javax.inject.Inject

/**
 * Mirrors iOS `PDFDocumentListViewModel`: on import, copy the picked file into
 * app-private storage (here: filesDir/pdfs/) so it survives after the picker's
 * Uri permission grant ends, matching iOS's copy-into-Documents/PDFs approach.
 */
@HiltViewModel
class DocumentListViewModel @Inject constructor(
    private val repository: PdfDocumentRepository,
    @ApplicationContext private val context: Context,
) : ViewModel() {

    val documents: StateFlow<List<PdfDocument>> = repository.observeDocuments()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun importPdf(uri: Uri) {
        viewModelScope.launch {
            val pdfDir = File(context.filesDir, "pdfs").apply { mkdirs() }
            val displayName = queryDisplayName(uri) ?: "Document_${UUID.randomUUID().toString().take(6)}.pdf"
            var destFile = File(pdfDir, displayName)
            if (destFile.exists()) {
                destFile = File(pdfDir, "${destFile.nameWithoutExtension}_${UUID.randomUUID().toString().take(6)}.pdf")
            }

            context.contentResolver.openInputStream(uri)?.use { input ->
                destFile.outputStream().use { output -> input.copyTo(output) }
            } ?: return@launch

            val pageCount = countPdfPages(destFile)

            repository.save(
                PdfDocument(
                    title = destFile.nameWithoutExtension,
                    filePath = destFile.absolutePath,
                    pageCount = pageCount,
                    fileSizeBytes = destFile.length(),
                    createdAtEpochMillis = System.currentTimeMillis(),
                    sourceTool = SourceTool.IMPORTED,
                )
            )
        }
    }

    fun delete(document: PdfDocument) {
        viewModelScope.launch {
            File(document.filePath).delete()
            repository.delete(document)
        }
    }

    private fun countPdfPages(file: File): Int = try {
        android.os.ParcelFileDescriptor.open(file, android.os.ParcelFileDescriptor.MODE_READ_ONLY).use { pfd ->
            android.graphics.pdf.PdfRenderer(pfd).use { renderer -> renderer.pageCount }
        }
    } catch (e: Exception) {
        0
    }

    private fun queryDisplayName(uri: Uri): String? {
        val cursor = context.contentResolver.query(uri, null, null, null, null) ?: return null
        cursor.use {
            val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            if (nameIndex >= 0 && it.moveToFirst()) return it.getString(nameIndex)
        }
        return null
    }
}
