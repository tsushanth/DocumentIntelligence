package com.kreativekoala.pdfgenius.tools.ocr

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
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

data class OcrUiState(
    val sourceFile: File? = null,
    val isExtracting: Boolean = false,
    val extractedText: String = "",
    val error: String? = null,
)

@HiltViewModel
class OcrToolViewModel @Inject constructor(
    private val engine: PdfToolsEngine,
    @ApplicationContext private val context: Context,
) : ViewModel() {

    private val _state = MutableStateFlow(OcrUiState())
    val state: StateFlow<OcrUiState> = _state.asStateFlow()

    fun pickFile(uri: Uri) {
        viewModelScope.launch {
            val file = PdfFileImporter.copyUriToWorkingFile(context, uri) ?: run {
                _state.update { it.copy(error = "Failed to import file.") }
                return@launch
            }
            _state.update { it.copy(sourceFile = file, extractedText = "") }
        }
    }

    fun extract() {
        val file = _state.value.sourceFile ?: return
        _state.update { it.copy(isExtracting = true, error = null) }
        viewModelScope.launch {
            try {
                val text = engine.extractText(file)
                _state.update { it.copy(isExtracting = false, extractedText = text) }
            } catch (e: Exception) {
                _state.update { it.copy(isExtracting = false, error = e.message ?: "Failed to extract text.") }
            }
        }
    }

    fun clearError() = _state.update { it.copy(error = null) }
}
