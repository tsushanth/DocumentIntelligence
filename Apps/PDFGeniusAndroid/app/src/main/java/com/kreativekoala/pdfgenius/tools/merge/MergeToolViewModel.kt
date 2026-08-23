package com.kreativekoala.pdfgenius.tools.merge

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kreativekoala.pdfgenius.data.PdfDocumentRepository
import com.kreativekoala.pdfgenius.data.model.PdfDocument
import com.kreativekoala.pdfgenius.data.model.SourceTool
import com.kreativekoala.pdfgenius.tools.PdfFileImporter
import com.kreativekoala.pdfgenius.tools.PdfToolsEngine
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

data class MergeUiState(
    val selectedFiles: List<File> = emptyList(),
    val isMerging: Boolean = false,
    val success: Boolean = false,
    val error: String? = null,
)

@HiltViewModel
class MergeToolViewModel @Inject constructor(
    private val engine: PdfToolsEngine,
    private val repository: PdfDocumentRepository,
    @ApplicationContext private val context: Context,
) : ViewModel() {

    private val _state = MutableStateFlow(MergeUiState())
    val state: StateFlow<MergeUiState> = _state.asStateFlow()

    fun addFiles(uris: List<Uri>) {
        viewModelScope.launch {
            val copied = uris.mapNotNull { PdfFileImporter.copyUriToWorkingFile(context, it) }
            _state.update { it.copy(selectedFiles = it.selectedFiles + copied) }
        }
    }

    fun removeFile(file: File) {
        _state.update { it.copy(selectedFiles = it.selectedFiles - file) }
    }

    fun merge() {
        val files = _state.value.selectedFiles
        if (files.size < 2) return
        _state.update { it.copy(isMerging = true, error = null) }
        viewModelScope.launch {
            try {
                val outDir = File(context.filesDir, "pdfs").apply { mkdirs() }
                val outFile = File(outDir, "Merged_${System.currentTimeMillis()}.pdf")
                engine.merge(files, outFile)
                repository.save(
                    PdfDocument(
                        title = outFile.nameWithoutExtension,
                        filePath = outFile.absolutePath,
                        pageCount = PdfFileImporter.countPdfPages(outFile),
                        fileSizeBytes = outFile.length(),
                        createdAtEpochMillis = System.currentTimeMillis(),
                        sourceTool = SourceTool.MERGED,
                    )
                )
                _state.update { it.copy(isMerging = false, success = true) }
            } catch (e: Exception) {
                _state.update { it.copy(isMerging = false, error = e.message ?: "Failed to merge PDFs.") }
            }
        }
    }

    fun clearError() = _state.update { it.copy(error = null) }
}
