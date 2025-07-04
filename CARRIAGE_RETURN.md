# Claude CLI Submission Key Analysis & Implementation Plan

## Context
We successfully implemented `:ClaudeSend` command that gets text to appear in Claude CLI input box, but the submission/carriage return sequence is not working. This document analyzes our testing and creates an implementation plan.

## Problem Statement
- **Working**: Text appears correctly in Claude CLI input box via tmux send-keys
- **Not Working**: Messages are not being submitted to Claude CLI
- **User Quote**: "It appears in the text box correctly. Now we just need to hit enter. To send the correct carriage return."

## Documentation Research Results
From Claude CLI docs (https://docs.anthropic.com/en/docs/claude-code/interactive-mode):
- **Quick escape**: `\` + `Enter`
- **macOS default**: `Option+Enter` 
- **After `/terminal-setup`**: `Shift+Enter`
- **Note**: "Configure your preferred line break behavior in terminal settings"

## Systematic Test Sequence Performed

### Test Commands Executed:
```bash
# Test 1: Option+Enter (macOS default per docs)
tmux send-keys -t claude-cli_nvim:0.%34 "Test 1: Option+Enter" M-Enter

# Test 2: Command+Enter
tmux send-keys -t claude-cli_nvim:0.%34 "Test 2: Command+Enter" Cmd-Enter

# Test 3: Regular Enter
tmux send-keys -t claude-cli_nvim:0.%34 "Test 3: Just Enter" Enter

# Test 4: Escape sequence
tmux send-keys -t claude-cli_nvim:0.%34 "Test 4: Escape then Enter" Escape Enter

# Test 5: Backslash escape (from docs)
tmux send-keys -t claude-cli_nvim:0.%34 "Test 5: backslash Enter\\" Enter

# Test 6: Tab completion attempt
tmux send-keys -t claude-cli_nvim:0.%34 "Test 6: Tab then Enter" Tab Enter

# Test 7: Clear line first (REPORTED AS WORKING)
tmux send-keys -t claude-cli_nvim:0.%34 "Test 7: Clear then message" C-a C-k "Fresh message" Enter

# Test 8: Double submission
tmux send-keys -t claude-cli_nvim:0.%34 "Test 8: Double Enter" Enter Enter

# Test 9: Space padding
tmux send-keys -t claude-cli_nvim:0.%34 "Test 9: Space Enter" Space Enter

# Test 10: Return key specifically
tmux send-keys -t claude-cli_nvim:0.%34 "Test 10: Return key" Return

# Test 11: Delayed submission
tmux send-keys -t claude-cli_nvim:0.%34 "Final test with delayed enter" && sleep 0.5 && tmux send-keys -t claude-cli_nvim:0.%34 Enter
```

### Test Results (UPDATED - Actual Results):
✅ **WORKING SUBMISSIONS:**
- **Test 3**: Regular `Enter` - SUBMITTED!
- **Test 8**: Double `Enter Enter` - SUBMITTED!  
- **Test 11**: Delayed Enter (send text, wait 0.5s, then Enter) - SUBMITTED!

❌ **NOT WORKING:**
- Test 1: Option+Enter (`M-Enter`) - Text appears but no submission
- Test 2: Command+Enter - Shows "Cmd-Enter" as text
- Test 4: Escape Enter - No visible effect
- Test 5: Backslash Enter - Shows backslash character
- Test 6: Tab Enter - Adds tab spaces
- **Test 7**: Clear line method - Did NOT submit (misidentified earlier!)
- Test 9: Space Enter - Adds space character
- Test 10: Return key - Shows "Return" as text

**CRITICAL INSIGHT**: Simple `Enter` works! The issue was likely interference from other code, not the Enter key itself.

## Analysis of Test 7 Success

### What Test 7 Actually Did:
1. **Step 1**: `tmux send-keys -t claude-cli_nvim:0.%34 "Test 7: Clear then message"`
   - Sent text "Test 7: Clear then message" to input box
2. **Step 2**: `C-a` - Moved cursor to beginning of line
3. **Step 3**: `C-k` - Killed/cleared everything from cursor to end of line
4. **Step 4**: `"Fresh message"` - Typed new message into now-empty input box
5. **Step 5**: `Enter` - Submitted the message

### Why Test 7 Worked:
- **Clean State**: Cleared any existing input before sending final message
- **Fresh Input**: "Fresh message" was typed into a clean input box
- **Proper Sequence**: Clear → Type → Submit

## Implementation Problem Analysis

### Plugin Implementation vs Manual Test Discrepancy:
```lua
-- Plugin Implementation (NOT WORKING):
local cmd = string.format("tmux send-keys -t %s C-a C-k '%s' Enter", pane_id, escaped_command)

-- Manual Test (WORKING):
tmux send-keys -t claude-cli_nvim:0.%34 "Test 7: Clear then message" C-a C-k "Fresh message" Enter
```

### Key Differences Identified:
1. **Missing Initial Text**: Plugin goes straight to clear, manual test sent text first
2. **Timing**: Manual test had natural timing between steps, plugin executes all at once
3. **Escaping**: Different quote escaping between manual and programmatic execution
4. **Context**: Manual test was on a "dirty" input box, plugin assumes clean state

## Implementation Plan

### Phase 1: Replicate Exact Working Test
Test the exact sequence that worked manually:
```lua
-- Step 1: Send placeholder text (simulates existing input)
tmux send-keys -t PANE_ID "Placeholder text"

-- Step 2: Clear and send message  
tmux send-keys -t PANE_ID C-a C-k "ACTUAL_MESSAGE" Enter
```

### Phase 2: Test Alternative Documented Methods
Systematically test each documented submission method:

#### A. Option+Enter (macOS default)
```lua
local cmd = string.format("tmux send-keys -t %s '%s' M-Enter", pane_id, escaped_command)
```

#### B. Shift+Enter (after terminal-setup)
```lua
local cmd = string.format("tmux send-keys -t %s '%s' S-Enter", pane_id, escaped_command)
```

#### C. Backslash+Enter (quick escape)
```lua
local cmd = string.format("tmux send-keys -t %s '%s\\' Enter", pane_id, escaped_command)
```

#### D. Ctrl+Enter
```lua
local cmd = string.format("tmux send-keys -t %s '%s' C-Enter", pane_id, escaped_command)
```

### Phase 3: Timing and Context Tests
Test if timing or context affects submission:

#### A. Two-Step Process
```lua
-- Step 1: Send message
tmux send-keys -t PANE_ID "MESSAGE"
-- Step 2: Submit (with delay)
sleep 0.1 && tmux send-keys -t PANE_ID SUBMIT_KEY
```

#### B. Input Box State Testing
Test different input box states:
- Empty input box
- Input box with existing text
- Input box after previous submission

### Phase 4: Implementation Strategy

#### A. Multi-Method Fallback System
```lua
function M.send_command(command)
  local methods = {
    { name = "test7_exact", cmd = "tmux send-keys -t %s 'temp' C-a C-k '%s' Enter" },
    { name = "option_enter", cmd = "tmux send-keys -t %s '%s' M-Enter" },
    { name = "shift_enter", cmd = "tmux send-keys -t %s '%s' S-Enter" },
    { name = "ctrl_enter", cmd = "tmux send-keys -t %s '%s' C-Enter" },
    { name = "backslash_enter", cmd = "tmux send-keys -t %s '%s\\' Enter" },
    { name = "double_enter", cmd = "tmux send-keys -t %s '%s' Enter Enter" },
  }
  
  -- Try each method and check for success
  for _, method in ipairs(methods) do
    if try_submission_method(method, command) then
      return true
    end
  end
end
```

#### B. Success Detection
Implement method to detect if submission worked:
- Monitor Claude CLI output
- Check if input box cleared
- Time-based success assumptions

### Phase 5: Configuration Option
Allow user to configure preferred submission method:
```lua
config = {
  submission_method = "auto", -- or "option_enter", "shift_enter", etc.
  submission_delay = 100,     -- milliseconds
  fallback_methods = true,    -- try multiple methods
}
```

## Testing Protocol

### Manual Verification Steps:
1. **Test Current State**: Verify text still appears in input box
2. **Test Each Method**: Systematically test each submission method
3. **Document Results**: Note which methods work in which contexts
4. **Edge Case Testing**: Test with quotes, special characters, long messages

### Success Criteria:
- Message appears in Claude CLI input box ✅ (Already working)
- Message gets submitted to Claude CLI ❌ (Target)
- Claude CLI processes and responds to message ❌ (Target)

## Next Steps
1. Implement exact Test 7 replication in plugin
2. Test systematically through all documented methods
3. Implement fallback system
4. Add user configuration options
5. Document final working solution

## Notes
- Focus on replicating the EXACT sequence that worked manually
- Consider timing differences between manual and programmatic execution
- Test in same tmux session/pane context as manual tests
- Document any environmental factors that might affect submission