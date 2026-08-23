package com.kreativekoala.pdfgenius.tools.split

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

data class SplitUiState(
    val sourceFile: File? = null,
    val pageCount: Int = 0,
    val selectedPages: Set<Int> = emptySet(),
    val isSplitting: Boolean = false,
    val success: Boolean = false,
    val error: String? = null,
)

@HiltViewModel
class SplitToolViewModel @Inject constructor(
    private val engine: PdfToolsEngine,
    private val repository: PdfDocumentRepository,
    @ApplicationContext private val context: Context,
) : ViewModel() {

    private val _state = MutableStateFlow(SplitUiState())
    val state: StateFlow<SplitUiState> = _state.asStateFlow()

    fun pickFile(uri: Uri) {
        viewModelScope.launch {
            val file = PdfFileImporter.copyUriToWorkingFile(context, uri) ?: run {
                _state.update { it.copy(error = "Failed to import file.") }
                return@launch
            }
            val pageCount = PdfFileImporter.countPdfPages(file)
            _state.update { it.copy(sourceFile = file, pageCount = pageCount, selectedPages = emptySet()) }
        }
    }

    fun togglePage(index: Int) {
        _state.update {
            val newSet = if (it.selectedPages.contains(index)) it.selectedPages - index else it.selectedPages + index
            it.copy(selectedPages = newSet)
        }
    }

    fun split() {
        val file = _state.value.sourceFile ?: return
        val pages = _state.value.selectedPages
        if (pages.isEmpty()) return
        _state.update { it.copy(isSplitting = true, error = null) }
        viewModelScope.launch {
            try {
                val outDir = File(context.filesDir, "pdfs").apply { mkdirs() }
                val outFile = File(outDir, "Split_${System.currentTimeMillis()}.pdf")
                engine.split(file, pages.toList(), outFile)
                repository.save(
                    PdfDocument(
                        title = outFile.nameWithoutExtension,
                        filePath = outFile.absolutePath,
                        pageCount = PdfFileImporter.countPdfPages(outFile),
                        fileSizeBytes = outFile.length(),
                        createdAtEpochMillis = System.currentTimeMillis(),
                        sourceTool = SourceTool.SPLIT,
                    )
                )
                _state.update { it.copy(isSplitting = false, success = true) }
            } catch (e: Exception) {
                _state.update { it.copy(isSplitting = false, error = e.message ?: "Failed to split PDF.") }
            }
        }
    }

    fun clearError() = _state.update { it.copy(error = null) }
}
