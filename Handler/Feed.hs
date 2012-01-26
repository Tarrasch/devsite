module Handler.Feed 
    ( getFeedR
    , getFeedTagR
    ) where

import Import
import Yesod.RssFeed
import Yesod.Markdown
import System.Directory    (doesFileExist)
import Text.Blaze          (preEscapedText)
import Text.Blaze.Internal (HtmlM (Append))

getFeedR :: Handler RepRss
getFeedR = do
    posts' <- runDB $ selectList [] [Desc PostDate, LimitTo 10]
    case posts' of
        []    -> notFound
        posts -> feedFromPosts $ map entityVal posts

-- | Limited to a tag
getFeedTagR :: Text -> Handler RepRss
getFeedTagR tag = do
    posts' <- runDB $ do
        tags <- selectList [TagName ==. tag] []

        let pids = map (tagPost . entityVal) tags
        posts <- selectList [PostId <-. pids] [Desc PostDate]

        return $ map entityVal posts

    case posts' of
        []    -> notFound
        posts -> feedFromPosts posts

feedFromPosts :: [Post] -> Handler RepRss
feedFromPosts posts = do
    entries <- mapM postToRssEntry posts

    rssFeed Feed
        { feedTitle       = "pbrisbin dot com"
        , feedDescription = "New posts on pbrisbin dot com"
        , feedLanguage    = "en-us"
        , feedLinkSelf    = FeedR
        , feedLinkHome    = RootR
        , feedUpdated     = postDate $ head posts
        , feedEntries     = entries
        }

-- | Note: does not gracefully handle a post with no pandoc or in-db
--   content
postToRssEntry :: Post -> Handler (FeedEntry (Route DevSite))
postToRssEntry post = do
    let file = pandocFile $ postSlug post

    mkd <- liftIO $ do
        exists <- doesFileExist file
        case (exists, postDescr post) of
            (True, _         ) -> markdownFromFile file
            (_   , Just descr) -> return descr
            _                  -> return $ Markdown ""

    return FeedEntry
        { feedEntryLink    = PostR $ postSlug post
        , feedEntryUpdated = postDate  post
        , feedEntryTitle   = postTitle post
        , feedEntryContent = cdata mkd
        }

        where
            -- Rss validation warnings on "relative links" that I have
            -- in the markdown. Shows as one big blob (no line-breaks)
            -- in Google reader. Looks great in snownews.
            plainText :: Markdown -> Html
            plainText (Markdown s) = toHtml s

            -- Should appear as formatted HTML in readers that support
            -- that.Rss validation errors on script tage used by
            -- markdown conversion to obfuscate an email. Looks pretty
            -- bad in snownews (but readable) -- not sure about Google
            -- yet.
            cdata :: Markdown -> Html
            cdata mkd = let prefix  = preEscapedText "<![CDATA["
                            content = markdownToHtml mkd
                            suffix  = preEscapedText "]]>" in Append prefix $ Append content suffix
