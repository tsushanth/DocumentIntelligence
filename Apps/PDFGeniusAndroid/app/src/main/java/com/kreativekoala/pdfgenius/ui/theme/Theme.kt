package com.kreativekoala.pdfgenius.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Purple accent, matching iOS PDFContentView's `.tint(.purple)`.
private val PurplePrimary = Color(0xFF7C3AED)
private val PurpleContainer = Color(0xFFEDE4FF)

private val LightColors = lightColorScheme(
    primary = PurplePrimary,
    secondaryContainer = PurpleContainer,
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFFC4A6FF),
)

@Composable
fun PDFGeniusTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) DarkColors else LightColors
    MaterialTheme(
        colorScheme = colors,
        content = content
    )
}
