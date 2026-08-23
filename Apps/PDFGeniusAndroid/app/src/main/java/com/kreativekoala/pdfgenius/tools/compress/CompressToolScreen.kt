package com.kreativekoala.pdfgenius.tools.compress

import android.text.format.Formatter
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

/** Mirrors iOS CompressPDFView: pick a PDF, choose quality, compress, save. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CompressToolScreen(onDone: () -> Unit, viewModel: CompressToolViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()
    val context = LocalContext.current

    val picker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
    ) { uri -> uri?.let(viewModel::pickFile) }

    LaunchedEffect(state.success) { if (state.success) onDone() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Compress PDF") },
                navigationIcon = {
                    IconButton(onClick = onDone) { Icon(Icons.Default.ArrowBack, contentDescription = "Cancel") }
                },
            )
        },
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp)) {
            if (state.sourceFile == null) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                        Text("Choose a PDF to compress")
                        Button(onClick = { picker.launch("application/pdf") }, modifier = Modifier.padding(top = 12.dp)) {
                            Text("Choose PDF")
                        }
                    }
                }
            } else {
                Text(state.sourceFile?.name ?: "", style = androidx.compose.material3.MaterialTheme.typography.titleMedium)
                Text("Quality: ${state.quality}", modifier = Modifier.padding(top = 12.dp))
                Slider(
                    value = state.quality.toFloat(),
                    onValueChange = { viewModel.setQuality(it.toInt()) },
                    valueRange = 10f..90f,
                )

                state.result?.let { result ->
                    Text("Original: ${Formatter.formatShortFileSize(context, result.originalSize)}")
                    Text("Compressed: ${Formatter.formatShortFileSize(context, result.compressedSize)}")
                    Text("Savings: ${"%.1f".format(result.savingsPercent)}%")
                    Button(onClick = { viewModel.saveResult() }, modifier = Modifier.fillMaxWidth().padding(top = 12.dp)) {
                        Text("Save Compressed PDF")
                    }
                } ?: run {
                    Button(
                        onClick = { viewModel.compress() },
                        enabled = !state.isCompressing,
                        modifier = Modifier.fillMaxWidth().padding(top = 16.dp),
                    ) {
                        if (state.isCompressing) CircularProgressIndicator(modifier = Modifier.padding(end = 8.dp))
                        Text("Compress")
                    }
                }
            }
            state.error?.let { err -> Text(err, color = androidx.compose.material3.MaterialTheme.colorScheme.error) }
        }
    }
}
