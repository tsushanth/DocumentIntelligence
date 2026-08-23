package com.kreativekoala.pdfgenius.tools.convert

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.foundation.clickable
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.foundation.shape.RoundedCornerShape
import android.graphics.BitmapFactory

/** Mirrors iOS ConvertPDFView: render every page to an image, save selected ones to the gallery. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConvertToolScreen(onDone: () -> Unit, viewModel: ConvertToolViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()

    val picker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
    ) { uri -> uri?.let(viewModel::pickFile) }

    LaunchedEffect(state.success) { if (state.success) onDone() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Convert to Images") },
                navigationIcon = {
                    IconButton(onClick = onDone) { Icon(Icons.Default.ArrowBack, contentDescription = "Cancel") }
                },
            )
        },
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding).padding(12.dp)) {
            when {
                state.sourceFile == null -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                        Text("Choose a PDF to convert")
                        Button(onClick = { picker.launch("application/pdf") }, modifier = Modifier.padding(top = 12.dp)) {
                            Text("Choose PDF")
                        }
                    }
                }
                state.isConverting -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                        CircularProgressIndicator()
                        Text("Converting pages...", modifier = Modifier.padding(top = 8.dp))
                    }
                }
                state.convertedImages.isEmpty() -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Button(onClick = { viewModel.convert() }) { Text("Convert to Images") }
                }
                else -> {
                    Text("${state.convertedImages.size} pages converted")
                    LazyVerticalGrid(columns = GridCells.Fixed(2), modifier = Modifier.weight(1f)) {
                        items(state.convertedImages.size) { index ->
                            val file = state.convertedImages[index]
                            val bmp = remember(file) { BitmapFactory.decodeFile(file.absolutePath) }
                            val selected = state.selectedIndices.contains(index)
                            Box(
                                modifier = Modifier.padding(4.dp).clip(RoundedCornerShape(8.dp))
                                    .clickable { viewModel.toggleSelected(index) },
                            ) {
                                bmp?.let {
                                    Image(
                                        bitmap = it.asImageBitmap(),
                                        contentDescription = "Page ${index + 1}",
                                        contentScale = ContentScale.Fit,
                                        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)),
                                    )
                                }
                            }
                            Text(
                                "Page ${index + 1}${if (selected) " ✓" else ""}",
                                modifier = Modifier.padding(bottom = 8.dp),
                            )
                        }
                    }
                    Button(
                        onClick = { viewModel.saveSelected() },
                        enabled = state.selectedIndices.isNotEmpty(),
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                    ) {
                        Text("Save ${state.selectedIndices.size} image(s)")
                    }
                }
            }
            state.error?.let { err -> Text(err, color = androidx.compose.material3.MaterialTheme.colorScheme.error) }
        }
    }
}
