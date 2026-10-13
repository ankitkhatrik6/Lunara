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

    // OAuth2 scope for the Discord integration.
    //
    // Only "identify" is requested. It is the single unrestricted scope this build
    // actually uses: it lets the app learn who signed in (GET /users/@me) so the
    // linked account can be shown. It works for every user with no Discord approval.
    //
    // We deliberately do NOT request "rpc" (or "rpc.activities.write"): those are
    // local-RPC scopes that require Discord approval and are locked to the app owner
    // and a small tester list for unapproved apps. Requesting them makes sign-in fail
    // with invalid_scope for everyone else, and the normal Gateway must never be
    // driven with a user OAuth token.
    //
    // Rich Presence on mobile is published through the Discord Social SDK (a native
    // library), which this build does not ship. See DiscordRpcManager, which explains
    // this to the user instead of publishing over an unsupported transport.
    const val DISCORD_SCOPES = "identify"
}
