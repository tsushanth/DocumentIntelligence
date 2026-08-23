package com.kreativekoala.pdfgenius.di

import android.content.Context
import androidx.room.Room
import com.kreativekoala.pdfgenius.data.local.PDFGeniusDatabase
import com.kreativekoala.pdfgenius.data.local.PdfDocumentDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): PDFGeniusDatabase =
        Room.databaseBuilder(context, PDFGeniusDatabase::class.java, "pdfgenius.db")
            .fallbackToDestructiveMigration()
            .build()

    @Provides
    fun providePdfDocumentDao(database: PDFGeniusDatabase): PdfDocumentDao =
        database.pdfDocumentDao()
}
