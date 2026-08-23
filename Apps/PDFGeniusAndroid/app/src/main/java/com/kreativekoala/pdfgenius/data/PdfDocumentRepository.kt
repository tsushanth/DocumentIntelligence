package com.kreativekoala.pdfgenius.data

import com.kreativekoala.pdfgenius.data.local.PdfDocumentDao
import com.kreativekoala.pdfgenius.data.model.PdfDocument
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Mirrors iOS's `PDFDocumentListViewModel` (ViewModels/PDFDocumentListViewModel.swift):
 * imported PDFs are copied into app-private storage and tracked as rows, rather than
 * relying on the source Uri staying valid.
 */
@Singleton
class PdfDocumentRepository @Inject constructor(
    private val dao: PdfDocumentDao,
) {
    fun observeDocuments(): Flow<List<PdfDocument>> = dao.observeAll()

    suspend fun save(document: PdfDocument) = dao.upsert(document)

    suspend fun delete(document: PdfDocument) = dao.delete(document)
}
