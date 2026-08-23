package com.kreativekoala.pdfgenius.tools.compress

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

data class CompressUiState(
    val sourceFile: File? = null,
    val quality: Int = 50, // 1-100, matches iOS's 0.1-0.9 JPEG quality slider, scaled to Bitmap.compress's 1-100
    val isCompressing: Boolean = false,
    val result: PdfToolsEngine.CompressResult? = null,
    val outFile: File? = null,
    val success: Boolean = false,
    val error: String? = null,
)

@HiltViewModel
class CompressToolViewModel @Inject constructor(
    private val engine: PdfToolsEngine,
    private val repository: PdfDocumentRepository,
    @ApplicationContext private val context: Context,
) : ViewModel() {

    private val _state = MutableStateFlow(CompressUiState())
    val state: StateFlow<CompressUiState> = _state.asStateFlow()

    fun pickFile(uri: Uri) {
        viewModelScope.launch {
            val file = PdfFileImporter.copyUriToWorkingFile(context, uri) ?: run {
                _state.update { it.copy(error = "Failed to import file.") }
                return@launch
            }
            _state.update { it.copy(sourceFile = file, result = null) }
        }
    }

    fun setQuality(q: Int) = _state.update { it.copy(quality = q) }

    fun compress() {
        val file = _state.value.sourceFile ?: return
        _state.update { it.copy(isCompressing = true, error = null) }
        viewModelScope.launch {
            try {
                val outDir = File(context.filesDir, "tool_outputs").apply { mkdirs() }
                val outFile = File(outDir, "${file.nameWithoutExtension}_compressed.pdf")
                val result = engine.compress(file, _state.value.quality, outFile)
                _state.update { it.copy(isCompressing = false, result = result, outFile = outFile) }
            } catch (e: Exception) {
                _state.update { it.copy(isCompressing = false, error = e.message ?: "Failed to compress PDF.") }
            }
        }
    }

    fun saveResult() {
        val outFile = _state.value.outFile ?: return
        val source = _state.value.sourceFile
        viewModelScope.launch {
            try {
                val pdfDir = File(context.filesDir, "pdfs").apply { mkdirs() }
                val name = "${source?.nameWithoutExtension ?: "Compressed"}_compressed_${System.currentTimeMillis()}.pdf"
                val savedFile = File(pdfDir, name)
                outFile.copyTo(savedFile, overwrite = true)
                repository.save(
                    PdfDocument(
                        title = savedFile.nameWithoutExtension,
                        filePath = savedFile.absolutePath,
                        pageCount = PdfFileImporter.countPdfPages(savedFile),
                        fileSizeBytes = savedFile.length(),
                        createdAtEpochMillis = System.currentTimeMillis(),
                        sourceTool = SourceTool.COMPRESSED,
                    )
                )
                _state.update { it.copy(success = true) }
            } catch (e: Exception) {
                _state.update { it.copy(error = e.message ?: "Failed to save compressed PDF.") }
            }
        }
    }

    fun clearError() = _state.update { it.copy(error = null) }
}
