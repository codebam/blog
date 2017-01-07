--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Text.Pandoc.Options
import qualified Data.Set               as S
import           Data.Map.Lazy
import Data.Maybe (fromJust)

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
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
        route   $ metadataRoute $ \m -> customRoute (\i -> fromJust (lookupString "permalink" m) ++ ".html")
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/page.html"    defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*.md" $ do
        route   $ metadataRoute $ \m -> customRoute (\i -> fromJust (lookupString "permalink" m) ++ ".html")
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "posts/*.lhs" $ do
        route   $ metadataRoute $ \m -> customRoute (\i -> fromJust (lookupString "permalink" m) ++ ".html")
        compile $
          --pandocCompilerWith (def {readerExtensions = S.singleton Ext_literate_haskell}) (def {writerExtensions = S.singleton Ext_literate_haskell})
          pandocCompiler
          >>= loadAndApplyTemplate "templates/post.html"    postCtx
          >>= saveSnapshot "content"
          >>= loadAndApplyTemplate "templates/default.html" postCtx
          >>= relativizeUrls

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

feedConfig :: FeedConfiguration
feedConfig = FeedConfiguration
    {
        feedTitle = "/usr/sbin/blog",
        feedDescription = "Alex Beal's personal blog.",
        feedAuthorName = "Alex Beal",
        feedAuthorEmail = "",
        feedRoot = "http://usrsb.in"
    }

