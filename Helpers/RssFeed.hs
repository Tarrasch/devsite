{-# LANGUAGE QuasiQuotes #-}
-------------------------------------------------------------------------------
--
-- Module        : Helpers.RssFeed
-- Copyright     : Patrick Brisbin
-- License       : as-is
--
-- Maintainer    : Patrick Brisbin <me@pbrisbin.com>
-- Stability     : Unstable
-- Portability   : portable
--
-------------------------------------------------------------------------------
module Helpers.RssFeed
    ( RssFeed (..)
    , RssFeedEntry (..)
    , rssFeed
    , RepRss (..)
    , rssLink
    ) where

import Yesod
import System.Locale    (defaultTimeLocale)
import Data.Time.Clock  (UTCTime)
import Data.Time.Format (formatTime)

-- | This would normally be added in Yesod.Content
typeRss :: ContentType
typeRss = "application/rss+xml"

newtype RepRss = RepRss Content
instance HasReps RepRss where
    chooseRep (RepRss c) _ = return (typeRss, c)

rssFeed :: RssFeed (Route master) -> GHandler sub master RepRss
rssFeed = fmap RepRss . hamletToContent . template

data RssFeed url = RssFeed
    { rssTitle       :: String
    , rssLinkSelf    :: url
    , rssLinkHome    :: url
    , rssDescription :: String
    , rssLanguage    :: String
    , rssUpdated     :: UTCTime
    , rssEntries     :: [RssFeedEntry url]
    }

data RssFeedEntry url = RssFeedEntry
    { rssEntryLink    :: url
    , rssEntryUpdated :: UTCTime
    , rssEntryTitle   :: String
    , rssEntryContent :: Html
    }

template :: RssFeed url -> Hamlet url
template arg = [$xhamlet|
%rss!version="2.0"!xmlns:atom="http://www.w3.org/2005/Atom"

    %channel
        %atom:link!href=@rssLinkSelf.arg@!rel="self"!type="application/rss+xml"
        %title         $rssTitle.arg$
        %link          @rssLinkHome.arg@
        %description   $rssDescription.arg$
        %lastBuildDate $format.rssUpdated.arg$
        %language      $rssLanguage.arg$

        $forall rssEntries.arg entry
            ^entryTemplate.entry^
|]

entryTemplate :: RssFeedEntry url -> Hamlet url
entryTemplate arg = [$xhamlet|
%item
    %title       $rssEntryTitle.arg$
    %link        @rssEntryLink.arg@
    %guid        @rssEntryLink.arg@
    %pubDate     $format.rssEntryUpdated.arg$
    %description $rssEntryContent.arg$
|]

-- | Format as string
format :: UTCTime -> String
format = formatTime defaultTimeLocale rfc822DateFormat

-- | System.Local.rfc822DateFormat disagrees with date -R and does not
--   validate, this one does.
rfc822DateFormat :: String
rfc822DateFormat = "%a, %d %b %Y %H:%M:%S %z"

-- | Generates a link tag in the head of a widget.
rssLink :: Route m
        -> String -- ^ title
        -> GWidget s m ()
rssLink u title = addHamletHead [$hamlet|
    %link!href=@u@!type=$typeRss$!rel="alternate"!title=$title$
    |]
