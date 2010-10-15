{-# LANGUAGE TemplateHaskell #-}
-------------------------------------------------------------------------------
-- |
-- Module      :  Handlers
-- Copyright   :  (c) Patrick Brisbin 2010 
-- License     :  as-is
--
-- Maintainer  :  pbrisbin@gmail.com
-- Stability   :  unstable
-- Portability :  unportable
--
-- Handler functions for each of the site's routes.
--
-------------------------------------------------------------------------------
module Handlers
    ( getRootR
    , getAboutR
    , getPostsR
    , getPostR
    , getTagsR
    , getTagR
    , getFeedR
    , getFaviconR
    , getRobotsR
    ) where

import Yesod
import DevSite
import Posts
import Layouts
import Templates
import qualified Settings as S
import Helpers.RssFeed
 
import Data.Maybe       (mapMaybe)
import Data.Time.Clock  (UTCTime)
import Data.Time.Format (parseTime)
import System.Locale    (defaultTimeLocale)

-- | Home page
getRootR :: Handler RepHtml
getRootR = defaultLayout $ do
    let posts = take 10 allPosts
    setTitle $ string "pbrisbin - Home"
    addBody $(S.hamletFile "index")
     
-- | About page
getAboutR :: Handler RepHtml
getAboutR = pageLayout $ do
    setTitle $ string "pbrisbin - About"
    addBody $(S.hamletFile "about")

-- | All posts
getPostsR :: Handler RepHtml
getPostsR = pageLayout $ do
    setTitle $ string "pbrisbin - All Posts"
    addBody  $ allPostsTemplate allPosts "All Posts"

-- | A post
getPostR :: String -> Handler RepHtml
getPostR slug = do
    case loadPost slug of
        []       -> notFound
        (post:_) -> postLayout post

-- | All tags
getTagsR :: Handler RepHtml
getTagsR = pageLayout $ do
    setTitle $ string "pbrisbin - All Tags"
    addBody  $ allPostsTemplate allPosts "All Tags"

-- | A tag
getTagR :: String -> Handler RepHtml
getTagR tag = do
    case getPostsByTag tag of
        []    -> notFound
        posts -> pageLayout $ do
            setTitle $ string $ "pbrisbin - Tag: " ++ tag
            addBody  $ allPostsTemplate posts ("Tag: " ++ tag)

-- | Rss feed
getFeedR :: Handler RepRss
getFeedR = do
    rssFeed RssFeed
        { rssTitle       = "pbrisbin dot com"
        , rssDescription = "New posts on pbrisbin dot com"
        , rssLanguage    = "en-us"
        , rssLinkSelf    = FeedR
        , rssLinkHome    = RootR
        , rssUpdated     = mostRecent
        , rssEntries     = take 10 $ mapMaybe readRssEntry allPosts
        }
        where
            -- todo: head of empty list
            mostRecent = rssEntryUpdated . head $ mapMaybe readRssEntry allPosts

-- | Maybe read a single post into an RssEntry depending if the date
--   string can be parsed correctly
readRssEntry :: Post -> Maybe (RssFeedEntry DevSiteRoute)
readRssEntry post = case (readUTCTime $ postDate post) of
    Just date -> Just $ RssFeedEntry
        { rssEntryLink    = PostR $ postSlug post
        , rssEntryUpdated = date
        , rssEntryTitle   = postTitle post
        , rssEntryContent = string $ postDescr post
        }
    Nothing -> Nothing

-- | Read the output of `date -R` into a UTCTime
readUTCTime :: String -> Maybe UTCTime
readUTCTime = parseTime defaultTimeLocale rfc822DateFormat

-- | An alternative to System.Local.rfc822DateFormat, this one agrees
--   with the output of `date -R`
rfc822DateFormat :: String
rfc822DateFormat = "%a, %d %b %Y %H:%M:%S %z"

-- | Favicon
getFaviconR :: Handler ()
getFaviconR = sendFile "image/x-icon" "favicon.ico"

-- | Robots
getRobotsR :: Handler RepPlain
getRobotsR = return $ RepPlain $ toContent "User-agent: *"
