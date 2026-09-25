## GoldenPad Preview 11 is out 🎮

New iPhone/iPad build: **0.1.0 · build 12**

This update brings a few under-the-hood reliability fixes:
• Corrected how the runtime detects connected controller ports and handles failed controller reads.
• Fixed a message-queue case where one full queue could hold up unrelated runtime work.
• Added a rendering check for invalid video dimensions.

Tested on a physical iPad, with existing saves, ROM and settings verified intact after updating. These are targeted fixes—not a claimed FPS boost or an A12X fix. Online play is still unsupported, and local multiplayer remains experimental.

**Download:** https://github.com/chrissotraidis/goldenpad/releases/tag/v0.1.0-preview.11

iOS/iPadOS 17+. The IPA is unsigned: use your usual sideloading setup and update over your existing install. Don’t delete the app. Bring your own supported ROM.

If something breaks, use **••• → Report a Problem** and include your device, build and what happened. The Mac download remains Preview 9.
