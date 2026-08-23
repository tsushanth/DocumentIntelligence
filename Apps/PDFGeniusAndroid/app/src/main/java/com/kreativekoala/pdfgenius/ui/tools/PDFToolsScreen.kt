package com.kreativekoala.pdfgenius.ui.tools

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController

/** Route constants for the per-tool full-screen flows launched from the tool grid. */
object ToolRoute {
    const val MERGE = "tool_merge"
    const val SPLIT = "tool_split"
    const val COMPRESS = "tool_compress"
    const val CONVERT = "tool_convert"
    const val PASSWORD = "tool_password"
    const val OCR = "tool_ocr"
}

/**
 * Mirrors iOS PDFToolsView's 6-tool grid (Merge, Split, Compress, Convert,
 * Password, OCR). Merge/Split/Compress/Convert/OCR are real, working
 * implementations (see com.kreativekoala.pdfgenius.tools.*); Password is a clearly
 * labeled "Coming soon" flow since it needs encryption support Android's built-in
 * PDF APIs don't provide.
 */
data class PdfTool(val label: String, val isPro: Boolean, val route: String)

// All tools free for the initial launch -- billing/paywall intentionally deferred,
// see repo notes. Re-introduce isPro gating later if/when a paywall ships.
private val TOOLS = listOf(
    PdfTool("Merge", isPro = false, route = ToolRoute.MERGE),
    PdfTool("Split", isPro = false, route = ToolRoute.SPLIT),
    PdfTool("Compress", isPro = false, route = ToolRoute.COMPRESS),
    PdfTool("Convert", isPro = false, route = ToolRoute.CONVERT),
    PdfTool("Password", isPro = false, route = ToolRoute.PASSWORD),
    PdfTool("OCR", isPro = false, route = ToolRoute.OCR),
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PDFToolsScreen(navController: NavController) {
    Scaffold(topBar = { TopAppBar(title = { Text("Tools") }) }) { padding ->
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            modifier = Modifier.fillMaxSize().padding(padding).padding(12.dp),
        ) {
            items(TOOLS) { tool -> ToolCard(tool, onClick = { navController.navigate(tool.route) }) }
        }
    }
}

@Composable
private fun ToolCard(tool: PdfTool, onClick: () -> Unit) {
    Card(modifier = Modifier.padding(8.dp).fillMaxSize().clickable(onClick = onClick)) {
        Box(modifier = Modifier.padding(16.dp), contentAlignment = Alignment.Center) {
            Text(tool.label)
            if (tool.isPro) {
                Icon(Icons.Default.Lock, contentDescription = "Pro feature")
            }
        }
    }
}
