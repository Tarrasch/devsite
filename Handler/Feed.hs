{-# LANGUAGE OverloadedStrings #-}
module Handler.Feed 
    ( getFeedR
    , getFeedTagR
    ) where

import Foundation
import Yesod.RssFeed
import Data.Text (Text)

getFeedR :: Handler RepRss
getFeedR = do
    docs' <- siteDocs =<< getYesod
    case docs' of
        []   -> notFound
        docs -> feedFromDocs $ take 10 docs

-- | Limited to a tag
getFeedTagR :: Text -> Handler RepRss
getFeedTagR tag = do
    docs' <- siteDocs =<< getYesod
    case filter (hasTag tag) docs' of
        []   -> notFound
        docs -> feedFromDocs docs

feedFromDocs :: [Document] -> Handler RepRss
feedFromDocs docs = rssFeed Feed
    { feedTitle       = "pbrisbin dot com"
    , feedDescription = "New posts on pbrisbin dot com"
    , feedLanguage    = "en-us"
    , feedLinkSelf    = FeedR
    , feedLinkHome    = RootR
    , feedUpdated     = postDate . post $ head docs
    , feedEntries     = map docToRssEntry docs
    }

docToRssEntry :: Document -> FeedEntry DevSiteRoute
docToRssEntry (Document p _) = FeedEntry
    { feedEntryLink    = PostR $ postSlug p
    , feedEntryUpdated = postDate  p
    , feedEntryTitle   = postTitle p
    , feedEntryContent = plainText $ postDescr p
    }

    where
        plainText :: Markdown -> Html
        plainText (Markdown s) = toHtml s
