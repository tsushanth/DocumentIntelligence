package com.kreativekoala.pdfgenius.tools.merge

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

/** Mirrors iOS MergePDFsView: pick 2+ PDFs, merge into one, save to the document list. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MergeToolScreen(onDone: () -> Unit, viewModel: MergeToolViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()

    val picker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents(),
    ) { uris -> if (uris.isNotEmpty()) viewModel.addFiles(uris) }

    LaunchedEffect(state.success) { if (state.success) onDone() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Merge PDFs") },
                navigationIcon = {
                    IconButton(onClick = onDone) { Icon(Icons.Default.ArrowBack, contentDescription = "Cancel") }
                },
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { picker.launch("application/pdf") }) {
                Icon(Icons.Default.Add, contentDescription = "Add PDFs")
            }
        },
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            if (state.selectedFiles.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Tap + to add 2 or more PDFs to combine")
                }
            } else {
                LazyColumn(modifier = Modifier.weight(1f)) {
                    items(state.selectedFiles) { file ->
                        ListItem(
                            headlineContent = { Text(file.name) },
                            leadingContent = { Icon(Icons.Default.PictureAsPdf, contentDescription = null) },
                            trailingContent = {
                                IconButton(onClick = { viewModel.removeFile(file) }) {
                                    Icon(Icons.Default.Delete, contentDescription = "Remove")
                                }
                            },
                        )
                    }
                }
                Row(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                    Button(
                        onClick = { viewModel.merge() },
                        enabled = state.selectedFiles.size >= 2 && !state.isMerging,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        if (state.isMerging) {
                            CircularProgressIndicator(modifier = Modifier.padding(end = 8.dp))
                        }
                        Text("Merge ${state.selectedFiles.size} PDFs")
                    }
                }
            }
            state.error?.let { err ->
                Card(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                    Text(err, modifier = Modifier.padding(12.dp))
                }
            }
        }
    }
}
