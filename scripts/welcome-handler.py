#!/usr/bin/env python3
"""
Helios-Kernel Welcome Bot Handler
Run this script to auto-welcome new members in Community group.
"""
import telegram
import json
import os

BOT_TOKEN = "YOUR_BOT_TOKEN_HERE"
COMMUNITY_ID = "-1004352095393"

WELCOME_MSG = """
👋 Welcome to Helios-Kernel Community!

Custom kernel for OnePlus 12 (waffle/SM8650)

📥 Downloads: /download
❓ Help: /help  
👥 Groups: /group

Be respectful and follow rules! 🚀
"""

bot = telegram.Bot(token=BOT_TOKEN)
update_id = 0

print("Welcome handler started...")

while True:
    try:
        updates = bot.get_updates(offset=update_id, timeout=30)
        for u in updates:
            update_id = u.update_id + 1
            if u.message and u.message.new_chat_member:
                try:
                    bot.send_message(
                        chat_id=u.message.chat.id,
                        text=f"Welcome {u.message.new_chat_member.first_name}! 👋\n\n{WELCOME_MSG}"
                    )
                    print(f"Welcome sent to {u.message.new_chat_member.first_name}")
                except Exception as e:
                    print(f"Error: {e}")
    except Exception as e:
        print(f"Polling error: {e}")
        import time
        time.sleep(5)
