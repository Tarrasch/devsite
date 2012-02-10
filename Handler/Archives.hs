module Handler.Archives (getArchivesR) where

import Import
import Helpers.Admin
import Helpers.Post

getArchivesR :: Handler RepHtml
getArchivesR = do
    now     <- liftIO $ getCurrentTime
    isAdmin <- maybeAdmin

    posts <- runDB $ selectList [PostDraft !=. True] [Desc PostDate]

    defaultLayout $ do
        setTitle "Archives"
        $(widgetFile "archives")
