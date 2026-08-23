package com.kreativekoala.pdfgenius.tools.convert

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
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

data class ConvertUiState(
    val sourceFile: File? = null,
    val isConverting: Boolean = false,
    val convertedImages: List<File> = emptyList(),
    val selectedIndices: Set<Int> = emptySet(),
    val savedCount: Int = 0,
    val success: Boolean = false,
    val error: String? = null,
)

@HiltViewModel
class ConvertToolViewModel @Inject constructor(
    private val engine: PdfToolsEngine,
    @ApplicationContext private val context: Context,
) : ViewModel() {

    private val _state = MutableStateFlow(ConvertUiState())
    val state: StateFlow<ConvertUiState> = _state.asStateFlow()

    fun pickFile(uri: Uri) {
        viewModelScope.launch {
            val file = PdfFileImporter.copyUriToWorkingFile(context, uri) ?: run {
                _state.update { it.copy(error = "Failed to import file.") }
                return@launch
            }
            _state.update { it.copy(sourceFile = file, convertedImages = emptyList()) }
        }
    }

    fun convert() {
        val file = _state.value.sourceFile ?: return
        _state.update { it.copy(isConverting = true, error = null) }
        viewModelScope.launch {
            try {
                val outDir = File(context.cacheDir, "converted_images")
                val images = engine.convertToImages(file, outDir)
                _state.update {
                    it.copy(isConverting = false, convertedImages = images, selectedIndices = images.indices.toSet())
                }
            } catch (e: Exception) {
                _state.update { it.copy(isConverting = false, error = e.message ?: "Failed to convert PDF.") }
            }
        }
    }

    fun toggleSelected(index: Int) {
        _state.update {
            val newSet = if (it.selectedIndices.contains(index)) it.selectedIndices - index else it.selectedIndices + index
            it.copy(selectedIndices = newSet)
        }
    }

    fun selectAll() = _state.update { it.copy(selectedIndices = it.convertedImages.indices.toSet()) }
    fun deselectAll() = _state.update { it.copy(selectedIndices = emptySet()) }

    /**
     * Saves the selected PNGs to the public Pictures/PDFGenius gallery collection via
     * MediaStore -- no storage permission needed on API 29+ (this app's minSdk is 26,
     * so on 26-28 we fall back to the app's own external files dir, which needs no
     * permission but isn't gallery-visible; that's a real Android platform constraint,
     * not a shortcut).
     */
    fun saveSelected() {
        val images = _state.value.selectedIndices.sorted().mapNotNull { _state.value.convertedImages.getOrNull(it) }
        if (images.isEmpty()) return
        viewModelScope.launch {
            try {
                var saved = 0
                for (img in images) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val values = ContentValues().apply {
                            put(MediaStore.Images.Media.DISPLAY_NAME, img.name)
                            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                            put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/PDFGenius")
                        }
                        val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                        uri?.let {
                            context.contentResolver.openOutputStream(it)?.use { out -> img.inputStream().use { input -> input.copyTo(out) } }
                            saved++
                        }
                    } else {
                        val dir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)?.apply { mkdirs() }
                        if (dir != null) {
                            img.copyTo(File(dir, img.name), overwrite = true)
                            saved++
                        }
                    }
                }
                _state.update { it.copy(savedCount = saved, success = saved > 0) }
            } catch (e: Exception) {
                _state.update { it.copy(error = e.message ?: "Failed to save images.") }
            }
        }
    }

    fun clearError() = _state.update { it.copy(error = null) }
}
