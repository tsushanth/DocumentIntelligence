package com.kreativekoala.pdfgenius.tools.split

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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

/** Mirrors iOS SplitPDFView: pick one PDF, tap pages to extract into a new PDF. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SplitToolScreen(onDone: () -> Unit, viewModel: SplitToolViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsState()

    val picker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
    ) { uri -> uri?.let(viewModel::pickFile) }

    LaunchedEffect(state.success) { if (state.success) onDone() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Split PDF") },
                navigationIcon = {
                    IconButton(onClick = onDone) { Icon(Icons.Default.ArrowBack, contentDescription = "Cancel") }
                },
            )
        },
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding).padding(12.dp)) {
            if (state.sourceFile == null) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                        Text("Choose a PDF to split")
                        Button(onClick = { picker.launch("application/pdf") }, modifier = Modifier.padding(top = 12.dp)) {
                            Text("Choose PDF")
                        }
                    }
                }
            } else {
                Text("${state.sourceFile?.name} — ${state.pageCount} pages")
                LazyVerticalGrid(
                    columns = GridCells.Fixed(5),
                    modifier = Modifier.weight(1f).padding(top = 8.dp),
                ) {
                    items(state.pageCount) { index ->
                        val selected = state.selectedPages.contains(index)
                        Card(
                            modifier = Modifier.padding(4.dp).size(50.dp),
                            colors = androidx.compose.material3.CardDefaults.cardColors(
                                containerColor = if (selected) androidx.compose.material3.MaterialTheme.colorScheme.primary
                                else androidx.compose.material3.MaterialTheme.colorScheme.surfaceVariant,
                            ),
                            onClick = { viewModel.togglePage(index) },
                        ) {
                            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                Text("${index + 1}")
                            }
                        }
                    }
                }
                if (state.selectedPages.isNotEmpty()) {
                    Button(
                        onClick = { viewModel.split() },
                        enabled = !state.isSplitting,
                        modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
                    ) {
                        if (state.isSplitting) CircularProgressIndicator(modifier = Modifier.padding(end = 8.dp))
                        Text("Extract ${state.selectedPages.size} page(s)")
                    }
                }
            }
            state.error?.let { err -> Text(err, color = androidx.compose.material3.MaterialTheme.colorScheme.error) }
        }
    }
}
