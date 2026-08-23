package com.kreativekoala.pdfgenius.ui.documents

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.kreativekoala.pdfgenius.data.model.PdfDocument

/** Mirrors iOS DocumentListView: PDF library home screen, import via file picker. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DocumentListScreen(
    viewModel: DocumentListViewModel = hiltViewModel(),
) {
    val documents by viewModel.documents.collectAsState()

    val importLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
    ) { uri -> uri?.let(viewModel::importPdf) }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Documents") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { importLauncher.launch("application/pdf") }) {
                Icon(Icons.Default.Add, contentDescription = "Import PDF")
            }
        },
    ) { padding ->
        if (documents.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("No documents yet — tap + to import a PDF")
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                items(documents, key = { it.id }) { doc ->
                    DocumentRow(doc, onDelete = { viewModel.delete(doc) })
                }
            }
        }
    }
}

@Composable
private fun DocumentRow(document: PdfDocument, onDelete: () -> Unit) {
    Card(modifier = Modifier.padding(horizontal = 12.dp, vertical = 2.dp)) {
        ListItem(
            headlineContent = { Text(document.title) },
            supportingContent = { Text("${document.pageCount} pages") },
            leadingContent = { Icon(Icons.Default.PictureAsPdf, contentDescription = null) },
            trailingContent = {
                IconButton(onClick = onDelete) {
                    Icon(Icons.Default.Delete, contentDescription = "Delete")
                }
            },
        )
    }
}
