package com.kreativekoala.pdfgenius.ui.settings

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ListItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/** Mirrors iOS PDFSettingsView. Subscription-management row is TODO pending PaywallKit-Android wiring. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PDFSettingsScreen() {
    Scaffold(topBar = { TopAppBar(title = { Text("Settings") }) }) { padding ->
        ListItem(
            headlineContent = { Text("Manage Subscription") },
            supportingContent = { Text("Coming soon") },
            modifier = Modifier.fillMaxSize().padding(padding),
        )
    }
}
