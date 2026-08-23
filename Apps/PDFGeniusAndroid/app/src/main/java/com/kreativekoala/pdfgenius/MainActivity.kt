package com.kreativekoala.pdfgenius

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.kreativekoala.pdfgenius.ui.nav.PDFGeniusNavHost
import com.kreativekoala.pdfgenius.ui.theme.PDFGeniusTheme
import com.kreativekoala.ratingkit.RatingKit
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Mirrors iOS PDFContentView's per-open tracking that feeds its app-open
        // paywall trigger; RatingKit-Android's trackAppOpen additionally drives the
        // Play In-App Review prompt (the Android equivalent of iOS RatingKit).
        RatingKit.trackAppOpen(this)

        setContent {
            PDFGeniusTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    PDFGeniusNavHost()
                }
            }
        }
    }
}
