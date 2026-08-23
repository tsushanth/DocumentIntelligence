package com.kreativekoala.pdfgenius.tools.password

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/**
 * Genuinely "Coming soon" rather than a fake pass-through: Android's built-in
 * android.graphics.pdf package (PdfRenderer for reading, PdfDocument for writing)
 * has no API for PDF encryption/password-protection -- unlike iOS's PDFKit, which
 * exposes .ownerPasswordOption/.userPasswordOption directly. Implementing this for
 * real would require adding a third-party PDF-crypto-capable library (e.g.
 * PDFBox-Android). That's a real, scoped follow-up, not something to fake with a
 * no-op copy that silently claims success.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PasswordToolScreen(onDone: () -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Password Protect") },
                navigationIcon = {
                    IconButton(onClick = onDone) { Icon(Icons.Default.ArrowBack, contentDescription = "Back") }
                },
            )
        },
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding).padding(24.dp), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.padding(bottom = 12.dp))
                Text("Coming Soon", style = MaterialTheme.typography.titleLarge)
                Text(
                    "PDF password protection needs encryption support that Android's " +
                        "built-in PDF APIs don't provide. We're evaluating a library to add " +
                        "this safely in a future update.",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(top = 8.dp),
                )
            }
        }
    }
}
