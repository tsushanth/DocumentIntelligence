package com.kreativekoala.pdfgenius.tools.ocr

import android.content.ClipData
import android.content.ClipboardManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

/** Mirrors iOS OCRView: pick a PDF, run on-device OCR, show selectable/copyable text. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OcrToolScreen(onDone: () -> Unit, viewModel: OcrToolViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()
    val context = LocalContext.current

    val picker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
    ) { uri -> uri?.let(viewModel::pickFile) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("OCR - Extract Text") },
                navigationIcon = {
                    IconButton(onClick = onDone) { Icon(Icons.Default.ArrowBack, contentDescription = "Cancel") }
                },
                actions = {
                    if (state.extractedText.isNotEmpty()) {
                        IconButton(onClick = {
                            val clipboard = context.getSystemService(ClipboardManager::class.java)
                            clipboard.setPrimaryClip(ClipData.newPlainText("Extracted text", state.extractedText))
                        }) {
                            Icon(Icons.Default.ContentCopy, contentDescription = "Copy")
                        }
                    }
                },
            )
        },
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding).padding(12.dp)) {
            when {
                state.sourceFile == null -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                        Text("Choose a PDF to extract text from")
                        Button(onClick = { picker.launch("application/pdf") }, modifier = Modifier.padding(top = 12.dp)) {
                            Text("Choose PDF")
                        }
                    }
                }
                state.isExtracting -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                        CircularProgressIndicator()
                        Text("Extracting text from PDF...", modifier = Modifier.padding(top = 8.dp))
                    }
                }
                state.extractedText.isEmpty() -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Button(onClick = { viewModel.extract() }) { Text("Extract Text") }
                }
                else -> SelectionContainer {
                    Text(state.extractedText, modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()))
                }
            }
            state.error?.let { err -> Text(err, color = androidx.compose.material3.MaterialTheme.colorScheme.error) }
        }
    }
}
