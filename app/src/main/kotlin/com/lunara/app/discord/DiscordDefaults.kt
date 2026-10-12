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

    // Standard OAuth2 scopes for gateway-based Discord Rich Presence.
    // - identify: lets the app know who authorized (basic account identity)
    // - rpc: lets the app update the user's activity / Rich Presence over the
    //   gateway using the OAuth bearer token (this is what the app does).
    // NOTE: do NOT use "sdk.social_layer_presence" here — that is Discord's Social
    // SDK (game SDK) scope, which shows a bogus app name ("sdk.social_layer_presence"),
    // requests unrelated friend-list/presence permissions, and breaks the standard
    // redirect_uri (Discord renders the redirect target as "null").
    const val DISCORD_SCOPES = "identify rpc"
}
