package com.lunara.app.discord

object DiscordDefaults {
    const val YOUTUBE_WATCH_URL = "https://music.youtube.com/watch?v="

    const val BUTTON1_LABEL = "Listen on YouTube Music"
    const val BUTTON1_URL_TEMPLATE = "https://music.youtube.com/watch?v={song.id}"

    const val BUTTON2_LABEL = "Visit Lunara"
    const val BUTTON2_URL = "https://github.com/ankitkhatrik6/lunara"

    const val STATE_TEMPLATE = "{artist.name}"
    const val DETAILS_TEMPLATE = "{song.name}"

    const val ACTIVITY_TYPE = "2"
    const val ACTIVITY_NAME = ""

    const val USER_STATUS = "online"
    const val STATUS_IDLE = "idle"
    const val STATUS_DND = "dnd"

    const val ACTIVITY_TYPE_LISTENING = "2"
    const val ACTIVITY_TYPE_PLAYING = "0"
    const val ACTIVITY_TYPE_WATCHING = "3"
    const val ACTIVITY_TYPE_COMPETING = "5"

    const val UNKNOWN_ARTIST = "Unknown Artist"
    const val UNKNOWN_ALBUM = "Unknown Album"

    const val DISCORD_OAUTH_AUTHORIZE = "https://discord.com/oauth2/authorize"
    const val DISCORD_OAUTH_TOKEN = "https://discord.com/api/v10/oauth2/token"

    // OAuth2 scopes for the Discord Rich Presence integration.
    //
    // - identify: lets the app learn who authorized (basic account identity, used to
    //   greet the user in settings). This is the only scope needed to *display* who is
    //   connected.
    // - rpc: the scope historically tied to Discord's Rich Presence. It authorizes the
    //   bearer token to drive an activity. NOTE: Discord's *officially supported* RPC
    //   transport is IPC against a locally-running desktop client, and the only
    //   officially supported mobile path is the Discord Social SDK. This app instead
    //   speaks the gateway WebSocket directly with the user bearer token; whether that
    //   is accepted depends on Discord's server policy (it can be closed with code
    //   4001/4004/4014). See DiscordRpcManager / DiscordReconnectStrategy.
    //
    // Do NOT request "sdk.social_layer_presence" together with a custom redirect_uri:
    // that is the Discord Social SDK scope. On the standard consent screen it renders a
    // bogus app name ("sdk.social_layer_presence"), asks for unrelated friend/presence
    // permissions, and breaks the redirect target (Discord shows "null"). It is only
    // correct when actually integrating the Social SDK with its own client credentials.
    const val DISCORD_SCOPES = "identify rpc"
}
