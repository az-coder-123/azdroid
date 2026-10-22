# Text Arguments Must Not Be Trimmed

## 1. Context & Symptoms

On 2026-10-22, `android_type_text` with `text: " legacy"` typed `legacy`. Typing a sentence in parts (`"Hello "` then `"world"`) produced `Helloworld`. Worse, the new consolidated `android_input_text` treats an empty `text` as "clear the field", so `text: " "` (type a space) would have **cleared** the field.

## 2. Diagnostic Traces & Evidence

`McpArgumentMapExtension.getString` returns `toString().trim()`. `android_type_text`, `android_set_text`, and `android_set_clipboard` read their content with `getRequiredString`, which uses it, and the router read `text` the same way.

## 3. Root Cause Analysis

Trimming is right for names, IDs, and queries (`" com.example "`), and the helper applied it to every string. Text the user wants entered is content: its spaces are part of the value. Merging tools added a branch on that value (empty means clear), which turned a lost space into a destructive action.

## 4. Architectural Solution

`getOptionalText` and `getText` return the value as given; `getText` still rejects an empty value. The text tools, the clipboard, and `McpToolRouter` use them. Router tests check that `" "` types a space and that `"Hello "` keeps its space. Verified on the Moto: `wi`, `fi `, ` `, `x` produced `wifi  x`.

## 5. Prevention & Reusability Checklist

- [ ] Separate identifiers (trim) from content (keep as given) when reading arguments.
- [ ] When a value's emptiness selects a behavior, read it untrimmed and test whitespace-only input.
- [ ] Batch steps (`McpAdbBatchCompiler`) already keep text as given; keep it that way.
