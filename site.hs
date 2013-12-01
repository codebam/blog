--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Text.Pandoc.Options
import qualified Data.Set               as S
import           Data.Map


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    {-
     -match "images/*" $ do
     -    route   idRoute
     -    compile copyFileCompiler
     -}

    create ["rss.xml"] $ do
        route idRoute
        compile $ do
            let feedCtx = postCtx `mappend` bodyField "description"
            posts <- fmap (take 10) . recentFirst =<<
                loadAllSnapshots "posts/*" "content"
            renderRss feedConfig feedCtx posts

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "pages/*.md" $ do
        route   $ metadataRoute $ \m -> customRoute (\i -> m ! "permalink" ++ ".html")
        compile $ pandocCompilerWith defaultHakyllReaderOptions customWriterOptions
            >>= loadAndApplyTemplate "templates/page.html"    defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*.md" $ do
        route   $ metadataRoute $ \m -> customRoute (\i -> m ! "permalink" ++ ".html")
        compile $ pandocCompilerWith defaultHakyllReaderOptions customWriterOptions
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

{-
 -    create ["archive.html"] $ do
 -        route idRoute
 -        compile $ do
 -            posts <- recentFirst =<< loadAll "posts/*"
 -            let archiveCtx =
 -                    listField "posts" postCtx (return posts) `mappend`
 -                    constField "title" "Archives"            `mappend`
 -                    defaultContext
 -
 -            makeItem ""
 -                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
 -                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
 -                >>= relativizeUrls
 -}

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "favicon.ico" $ do
        route idRoute
        compile copyFileCompiler

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

customWriterOptions :: WriterOptions
customWriterOptions = defaultHakyllWriterOptions
    {
        writerHTMLMathMethod = MathJax "https://c328740.ssl.cf1.rackcdn.com/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML",
        writerExtensions = S.insert Ext_tex_math_dollars (writerExtensions defaultHakyllWriterOptions)
    }

feedConfig :: FeedConfiguration
feedConfig = FeedConfiguration
    {
        feedTitle = "/usr/sbin/blog",
        feedDescription = "Alex Beal's personal blog.",
        feedAuthorName = "Alex Beal",
        feedAuthorEmail = "",
        feedRoot = "http://usrsb.in"
    }

