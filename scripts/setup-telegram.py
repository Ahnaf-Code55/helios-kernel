#!/usr/bin/env python3
# Helios-Kernel Telegram Setup
# Requirements: python3, telethon
# Install: python3 -m venv /tmp/telethon-env && /tmp/telethon-env/bin/pip install telethon
# Run: /tmp/telethon-env/bin/python3 scripts/setup-telegram.py

import asyncio
from telethon import TelegramClient
from telethon.tl.functions.messages import CreateChatRequest
from telethon.tl.functions.channels import CreateChannelRequest
from telethon.tl.types import ChatAdminRights, ChannelAdminRights

# ── CONFIG ──────────────────────────────────────────────────────────────────
SESSION_NAME = "helios-kernel"

# Group/channel titles
UPDATE_CHANNEL_TITLE = "Helios-Kernel Updates"
TESTER_GROUP_TITLE = "Helios-Kernel Testers"
COMMUNITY_GROUP_TITLE = "Helios-Kernel Community"
# ────────────────────────────────────────────────────────────────────────────

async def main():
    print("Starting Helios-Kernel Telegram setup...\n")

    # Use existing session (will prompt for phone if not already saved)
    client = TelegramClient(SESSION_NAME, api_id=0, api_hash="")
    await client.start()

    me = await client.get_me()
    print(f"Logged in as: {me.first_name} ({me.username})\n")

    # 1. Create Update Channel
    print("Creating Update Channel...")
    update_channel = await client(CreateChannelRequest(
        title=UPDATE_CHANNEL_TITLE,
        about="Official release announcements for Helios-Kernel.\n\nDeveloper: Ahnaf Hossain\nhttps://github.com/Ahnaf-Code55/helios-kernel",
        megagroup=False
    ))
    update_channel_id = update_channel.chats[0].id
    print(f"  Created: {UPDATE_CHANNEL_TITLE}")
    print(f"  Link: https://t.me/+{await client.get_entity(update_channel_id)}")

    # 2. Create Tester Group
    print("\nCreating Tester Group...")
    tester_group = await client(CreateChatRequest(
        users=[me.id],
        title=TESTER_GROUP_TITLE
    ))
    tester_chat = tester_group.chats[0]
    print(f"  Created: {TESTER_GROUP_TITLE}")
    print(f"  Link: https://t.me/+{tester_chat.username}" if tester_chat.username else f"  ID: {tester_chat.id}")

    # Set tester group to public (optional — uncomment if you want a public username)
    # await client(UpdateUsernameRequest(test_group.chat_id.username, "HeliosKernelTesters"))

    # 3. Create Main Community Group
    print("\nCreating Main Community Group...")
    community_group = await client(CreateChatRequest(
        users=[me.id],
        title=COMMUNITY_GROUP_TITLE
    ))
    community_chat = community_group.chats[0]
    print(f"  Created: {COMMUNITY_GROUP_TITLE}")
    print(f"  Link: https://t.me/+{community_chat.username}" if community_chat.username else f"  ID: {community_chat.id}")

    # Save IDs to file for bot/scripts
    with open("telegram-setup.txt", "w") as f:
        f.write(f"UPDATE_CHANNEL_ID={update_channel_id}\n")
        f.write(f"TESTER_GROUP_ID={tester_chat.id}\n")
        f.write(f"COMMUNITY_GROUP_ID={community_chat.id}\n")

    print("\n✅ Setup complete! IDs saved to telegram-setup.txt")
    print("\nNext steps:")
    print("1. Set a public username on your channels/groups via Telegram settings")
    print("2. Add your bot as admin to the groups (for auto-posting)")
    print("3. To post updates automatically, create a bot via @BotFather and use Telethon with the bot token")

    await client.disconnect()

if __name__ == "__main__":
    print("NOTE: You need your API credentials from https://my.telegram.org\n")
    print("If you don't have them yet:")
    print("1. Go to https://my.telegram.org")
    print("2. Login → API development → Create application")
    print("3. Copy api_id and api_hash into this script\n")
    asyncio.run(main())
