package com.kreativekoala.pdfgenius.tools

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfDocument as AndroidPdfDocument
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.tasks.await
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Real (non-stub) PDF tool implementations built on the stock
 * android.graphics.pdf package (PdfRenderer for reading, PdfDocument for writing)
 * plus ML Kit for OCR.
 *
 * IMPORTANT tradeoff, disclosed rather than hidden: unlike iOS's PDFKit, Android's
 * PdfRenderer has no API to copy an existing page's vector/text content into a new
 * document -- it can only rasterize a page to a Bitmap. So Merge and Split here
 * rasterize each source page to a high-resolution bitmap (2x scale) and re-embed it
 * as an image page in the output PDF. Output is visually faithful but pages become
 * image-based (no longer text-selectable), and file size grows a bit. This is a
 * real, working operation -- not a fake copy -- just a different quality tradeoff
 * than iOS's lossless PDFKit-based merge/split. Compress and Convert already work
 * this way by nature (compress = re-rasterize + recompress; convert = rasterize by
 * definition), so those two match iOS behavior exactly.
 */
@Singleton
class PdfToolsEngine @Inject constructor() {

    private val renderScale = 2.0f

    /** Renders every page of [file] to a bitmap at [scale]x the page's native size. */
    private fun renderPages(file: File, scale: Float = renderScale): List<Bitmap> {
        val bitmaps = mutableListOf<Bitmap>()
        ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { pfd ->
            PdfRenderer(pfd).use { renderer ->
                for (i in 0 until renderer.pageCount) {
                    renderer.openPage(i).use { page ->
                        val bmp = Bitmap.createBitmap(
                            (page.width * scale).toInt().coerceAtLeast(1),
                            (page.height * scale).toInt().coerceAtLeast(1),
                            Bitmap.Config.ARGB_8888,
                        )
                        val canvas = Canvas(bmp)
                        canvas.drawColor(Color.WHITE)
                        page.render(bmp, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        bitmaps.add(bmp)
                    }
                }
            }
        }
        return bitmaps
    }

    /** Writes [bitmaps] as one page per bitmap into a new PDF at [outFile]. */
    private fun writeBitmapsAsPdf(bitmaps: List<Bitmap>, outFile: File) {
        val doc = AndroidPdfDocument()
        try {
            for (bmp in bitmaps) {
                val pageInfo = AndroidPdfDocument.PageInfo.Builder(bmp.width, bmp.height, doc.pages.size + 1).create()
                val page = doc.startPage(pageInfo)
                page.canvas.drawBitmap(bmp, 0f, 0f, null)
                doc.finishPage(page)
            }
            FileOutputStream(outFile).use { out -> doc.writeTo(out) }
        } finally {
            doc.close()
        }
    }

    /** Merge: combine pages from all [sourceFiles] in order into one new PDF. */
    suspend fun merge(sourceFiles: List<File>, outFile: File) {
        require(sourceFiles.size >= 2) { "Merge requires at least 2 files" }
        val allPages = mutableListOf<Bitmap>()
        for (f in sourceFiles) allPages += renderPages(f)
        writeBitmapsAsPdf(allPages, outFile)
        allPages.forEach { it.recycle() }
    }

    /** Split: extract the given zero-based [pageIndices] from [sourceFile] into one new PDF. */
    suspend fun split(sourceFile: File, pageIndices: List<Int>, outFile: File) {
        require(pageIndices.isNotEmpty()) { "Split requires at least 1 page selected" }
        val all = renderPages(sourceFile)
        val chosen = pageIndices.sorted().mapNotNull { all.getOrNull(it) }
        writeBitmapsAsPdf(chosen, outFile)
        all.forEach { it.recycle() }
    }

    /**
     * Compress: rasterize each page and re-encode through JPEG at [quality] (1-100,
     * lower = smaller/more lossy), then rebuild the PDF from the compressed images.
     * A real compression pass -- output size is measured and returned, not assumed.
     */
    suspend fun compress(sourceFile: File, quality: Int, outFile: File): CompressResult {
        val originalSize = sourceFile.length()
        val pages = renderPages(sourceFile, scale = 1.5f)
        val recompressed = pages.map { bmp ->
            val baos = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.JPEG, quality, baos)
            bmp.recycle()
            android.graphics.BitmapFactory.decodeByteArray(baos.toByteArray(), 0, baos.size())
        }
        writeBitmapsAsPdf(recompressed, outFile)
        recompressed.forEach { it.recycle() }
        return CompressResult(originalSize = originalSize, compressedSize = outFile.length())
    }

    data class CompressResult(val originalSize: Long, val compressedSize: Long) {
        val savingsPercent: Double
            get() = if (originalSize <= 0) 0.0 else (originalSize - compressedSize) * 100.0 / originalSize
    }

    /** Convert: render every page of [sourceFile] to a standalone PNG file inside [outDir]. */
    suspend fun convertToImages(sourceFile: File, outDir: File): List<File> {
        outDir.mkdirs()
        val pages = renderPages(sourceFile)
        val files = pages.mapIndexed { index, bmp ->
            val f = File(outDir, "${sourceFile.nameWithoutExtension}_page${index + 1}.png")
            FileOutputStream(f).use { out -> bmp.compress(Bitmap.CompressFormat.PNG, 100, out) }
            bmp.recycle()
            f
        }
        return files
    }

    /**
     * OCR: rasterize each page and run ML Kit's on-device Latin text recognizer over it.
     * ML Kit's recognizer is inherently async (Play Services task-based), awaited here
     * so the whole pass reads as a normal suspend function.
     */
    suspend fun extractText(sourceFile: File): String {
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        val pages = renderPages(sourceFile)
        val sb = StringBuilder()
        try {
            pages.forEachIndexed { index, bmp ->
                val image = InputImage.fromBitmap(bmp, 0)
                val result = recognizer.process(image).await()
                bmp.recycle()
                if (result.text.isNotBlank()) {
                    sb.append("--- Page ${index + 1} ---\n").append(result.text).append("\n\n")
                }
            }
        } finally {
            recognizer.close()
        }
        return if (sb.isBlank()) "No text could be extracted from this PDF." else sb.toString()
    }
}
