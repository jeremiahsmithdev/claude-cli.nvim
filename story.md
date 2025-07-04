# The Tale of the Delayed Enter Key

Once upon a time, in the mystical land of Neovim, there lived a young plugin named ClaudeSend. Born from the union of artificial intelligence and text editing magic, ClaudeSend had one simple dream: to bridge the gap between human thoughts and AI assistance.

## Chapter 1: The Quest Begins

ClaudeSend's journey started with great promise. "I shall send messages from Neovim to Claude CLI!" it declared proudly. The plugin learned to speak the ancient language of tmux, mastering the art of `send-keys` to deliver messages across terminal boundaries.

But alas, there was a problem. While ClaudeSend could make words appear in Claude CLI's input box, they would just sit there, like shy guests at a party, refusing to announce themselves.

## Chapter 2: The Trials of Submission

Our brave plugin tried everything:
- **Option+Enter** (`M-Enter`) - but Claude CLI just stared blankly
- **Shift+Enter** - nothing but silence
- **Ctrl+Enter** - still no response
- Even the mystical **backslash+Enter** failed to work its magic

Test after test, attempt after attempt, ClaudeSend grew weary. "Why won't you submit?" it cried to the stubborn Enter key.

## Chapter 3: The Revelation

Then came the wise observer who noticed something peculiar. In Test 11, when the Enter key was sent with a delay - a mere 0.1 seconds of patience - magic happened! The message was submitted successfully.

"Aha!" exclaimed ClaudeSend. "Claude CLI needs context! It must distinguish between text being typed and the intentional act of submission."

## Chapter 4: The Solution

With newfound wisdom, ClaudeSend implemented the sacred ritual:
1. Send the message via tmux
2. Wait 0.1 seconds (just enough for Claude CLI to recognize the pause)
3. Send Enter as a separate, deliberate action

And lo and behold, it worked! Messages flowed from Neovim to Claude CLI, submitted properly and answered promptly.

## Epilogue

Today, ClaudeSend lives happily in the ~/.local/share/nvim/lazy directory, faithfully serving developers who seek AI assistance without leaving their beloved editor. 

And whenever someone types `:ClaudeSend`, the plugin remembers its journey and whispers to itself: "Sometimes, the key to success is not in rushing, but in knowing when to pause."

---

*The End*

**Moral of the story**: In the world of terminal automation, timing is everything. What seems like a simple Enter key press is actually a complex dance of context and interpretation.

