package com.kreativekoala.pdfgenius.ui.nav

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Handyman
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.kreativekoala.pdfgenius.tools.compress.CompressToolScreen
import com.kreativekoala.pdfgenius.tools.convert.ConvertToolScreen
import com.kreativekoala.pdfgenius.tools.merge.MergeToolScreen
import com.kreativekoala.pdfgenius.tools.ocr.OcrToolScreen
import com.kreativekoala.pdfgenius.tools.password.PasswordToolScreen
import com.kreativekoala.pdfgenius.tools.split.SplitToolScreen
import com.kreativekoala.pdfgenius.ui.documents.DocumentListScreen
import com.kreativekoala.pdfgenius.ui.settings.PDFSettingsScreen
import com.kreativekoala.pdfgenius.ui.tools.PDFToolsScreen
import com.kreativekoala.pdfgenius.ui.tools.ToolRoute

/** Mirrors iOS PDFContentView's 3-tab TabView (Documents / Tools / Settings). */
private sealed class Tab(val route: String, val label: String) {
    data object Documents : Tab("documents", "Documents")
    data object Tools : Tab("tools", "Tools")
    data object Settings : Tab("settings", "Settings")
}

private val TABS = listOf(Tab.Documents, Tab.Tools, Tab.Settings)

@Composable
fun PDFGeniusNavHost() {
    val navController = rememberNavController()

    Scaffold(
        bottomBar = {
            NavigationBar {
                val currentEntry by navController.currentBackStackEntryAsState()
                val currentDestination = currentEntry?.destination

                TABS.forEach { tab ->
                    val selected = currentDestination?.hierarchy?.any { it.route == tab.route } == true
                    NavigationBarItem(
                        selected = selected,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = {
                            Icon(
                                when (tab) {
                                    Tab.Documents -> Icons.Default.Description
                                    Tab.Tools -> Icons.Default.Handyman
                                    Tab.Settings -> Icons.Default.Settings
                                },
                                contentDescription = tab.label,
                            )
                        },
                        label = { Text(tab.label) },
                    )
                }
            }
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = Tab.Documents.route,
            modifier = Modifier.padding(padding),
        ) {
            composable(Tab.Documents.route) { DocumentListScreen() }
            composable(Tab.Tools.route) { PDFToolsScreen(navController) }
            composable(Tab.Settings.route) { PDFSettingsScreen() }

            // Full-screen tool flows, mirroring iOS presenting each tool as a sheet.
            composable(ToolRoute.MERGE) { MergeToolScreen(onDone = { navController.popBackStack() }) }
            composable(ToolRoute.SPLIT) { SplitToolScreen(onDone = { navController.popBackStack() }) }
            composable(ToolRoute.COMPRESS) { CompressToolScreen(onDone = { navController.popBackStack() }) }
            composable(ToolRoute.CONVERT) { ConvertToolScreen(onDone = { navController.popBackStack() }) }
            composable(ToolRoute.PASSWORD) { PasswordToolScreen(onDone = { navController.popBackStack() }) }
            composable(ToolRoute.OCR) { OcrToolScreen(onDone = { navController.popBackStack() }) }
        }
    }
}
