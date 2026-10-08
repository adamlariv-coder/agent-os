---
name: email-triage
description: >
  Scan the last ~2 days of unread inbox mail via the session's connected
  Gmail-like MCP tool, skip automated/notification/newsletter senders, and
  create draft replies (never sent) for the threads that genuinely read as
  needing a personal response — matching the user's own tone from recent
  sent mail. Also checks the user's own recently-sent "how did the showing
  go" / feedback-request emails and drafts a short follow-up nudge for any
  that haven't gotten a reply. Trigger on requests like "check my email and
  draft replies", "triage my inbox", "draft responses to my emails", "catch
  me up on email and draft anything that needs a reply".
version: 1.1.1
author: AgentOS
protected: false
dependencies: []
last_updated: 2026-08-21
model: sonnet
---

# email-triage Skill

Interactive, on-demand inbox triage: read recent unread mail, decide what actually needs a
reply, and leave drafts — never sends anything. Distinct from a scheduled/cron routine; this
runs once, in the current session, against whatever Gmail-like MCP connector is already
available.

## Quick Reference

| Task | Approach |
|------|----------|
| Find the mail tools | Check session tools for a Gmail-like MCP (`search_threads`, `get_thread`, `list_drafts`, `create_draft`, …). If not loaded, `ToolSearch` for them by name fragment (e.g. `search_threads`). If none exist in the session, tell the user to connect one — don't guess a provider. |
| Pull the candidate set | `search_threads` with `is:unread in:inbox newer_than:2d` (a 2-day window covers a "last 24h" ask with slack for timezones/weekends), `view: THREAD_VIEW_MINIMAL`, paginate with `pageToken` until exhausted. |
| Sample tone | Pull ~5-10 `in:sent` threads, but see **Tone sampling** below — bulk/marketing sends are not representative. |
| Avoid duplicates | `list_drafts` (metadata view is enough) and cross-check `threadId` against candidates before drafting. |
| Classify | Apply the skip heuristics below per thread. Only the last message in a thread matters for "does this need a reply." |
| Draft | `get_thread` (or `get_message` on just the latest message if the thread is large/binary-heavy) for full context, then `create_draft` with `replyToMessageId` set to the message being replied to. |
| Check for unanswered feedback requests | Search the user's own **sent** mail from the last ~14 days for outbound "how did the showing go" style asks; for any where the recipient hasn't replied, draft a short follow-up nudge. See **Feedback-request follow-ups** below. |
| Report back | List what was drafted (one line each) and what was skipped and why, grouped by category — see **Reporting** below. |

---

## Critical Rules

- **Never send. Only `create_draft`.** No exceptions, regardless of how clear-cut a reply seems.
- **Skip anything already drafted.** Check `list_drafts` first; if a thread's ID already has a draft, leave it alone.
- **A message that doesn't ask anything doesn't need a reply.** A closing "thanks, have a great day!" with no question is noise, not signal — skip it. When in doubt, lean toward skipping rather than manufacturing a reply.
- **Match the user's real voice, not a generic assistant voice.** Short, casual, direct beats polished and long unless their own mail shows otherwise. See **Tone sampling**.
- **Don't recreate the account's HTML signature block.** Drafts should contain just the reply body — the account's own signature (if any) is appended separately by the mail client, and reconstructing a multi-hundred-line HTML sig from a sent-mail sample is wasted effort and fragile.
- **Report every decision, not just the drafts.** The value of this skill is as much in *what was correctly skipped* as what was drafted — a silent skip list looks like missed work.

---

## Classifying "needs a reply" vs. noise

**Skip — automated / bulk / no-reply territory:**
- Sender domain or address pattern suggests automation: `noreply@`, `no-reply@`, `notifications@`, `leads@`, `broadcast@`, `callcenter@`, `mailer-daemon@`, CRM/lead-alert systems, transactional platforms (e-signature requests, checklist/workflow tools, payment/EFT notices)
- Digest or hot-sheet style subjects ("Daily update", "Hot Sheet", delivery-status notifications)
- Newsletters, product update emails, webinar/course promos, "congrats you hit X" marketing
- Calendar invites/updates (informational, not correspondence)
- Auto-generated copies of messages the user already sent to someone else (e.g. a CRM's "here's a copy of what we sent your client" pattern)
- A message whose content requires action somewhere *other* than an email reply (sign a document, fill a form) — surface it in the report as "needs attention elsewhere," don't draft an email about it

**Draft — genuine personal correspondence:**
- A real person replied to something the user sent, and their message asks a question, raises a concern, or otherwise expects a response
- Ongoing back-and-forth where the last message is substantive, not just a sign-off

When a sender is ambiguous, open the thread and look at whether the *last* message reads like it's addressed to a specific person with specific content, versus templated/bulk phrasing.

---

## Tone sampling

A plain `in:sent` search often surfaces templated drip/marketing sends (CRM-automated "nurture" emails) rather than the user's actual voice — these are the wrong sample to imitate. Prefer, in order:
1. The user's own replies *within the candidate threads themselves* (e.g. an earlier reply in the same thread, or a reply in a similar recent thread) — this is the most reliable source since it's genuinely personal correspondence, not a template.
2. If none available, sample a few `in:sent` threads but skim for short, clearly personal 1:1 replies and discount anything that reads like a template (identical opening lines across multiple recipients, marketing-style structure).

Calibrate to what's actually observed — don't default to a generic "professional and friendly" tone if the user's real mail is terser or more casual than that.

---

## Drafting

- Use `replyToMessageId` on `create_draft` so the draft threads correctly under the original message.
- Keep the subject as `RE: <original subject>` (or whatever the thread already used).
- Body: plain text, in the sampled tone, addressing what the message actually asked. No filler, no re-explaining context the recipient already knows, no signature block.
- One draft per qualifying thread, replying to the latest message in it.

---

## Reporting

At the end, tell the user:
- What was drafted (thread/sender, one line on what the reply covers)
- What was skipped as automated/noise (grouped by category, not itemized one-by-one if the list is long)
- Any borderline calls made and why (e.g. a closing pleasantry with no question — mention it so the user can override if they disagree)
- Anything that needs action outside of email (signatures, forms) if encountered

---

## Feedback-request follow-ups

Beyond the inbox pass above, also check whether the user's own outbound "how did the showing
go" requests to other agents have gone unanswered, and draft a short nudge for the ones that
have. This runs every time the skill is invoked, as a second pass after inbox triage.

**Finding candidates:**
1. Search `in:sent` for the last ~14 days for messages that read as the user asking another
   agent about a showing — subject patterns like "`<name> - Showing Feedback <address>`" or
   "`<name> - How did it go at <address>?`", or body phrasing such as "Following up to find
   out how your clients felt...", "How did it go...", "What did your clients think...", "Any
   feedback?". These are always addressed as a **question to one external recipient** about
   *their* client's reaction.
2. **Distinguish requests from reports.** Not everything with "feedback" in the subject is a
   request awaiting a reply — the user may also *send* feedback summaries to their own seller
   clients (e.g. "Open House Feedback", a recap addressed to the property owner) or relay
   feedback they already collected. Those are statements/summaries, not questions, and are
   often addressed to two co-recipients (the sellers) rather than one external agent. Skip
   these — there's no reply to wait for.
3. For each genuine request thread, `get_thread` and check whether the **last message** is
   still from the user (no reply) or from the recipient (answered — skip, nothing to do).
4. **Bound the window to ~14 days.** Older unanswered requests are usually moot — the listing
   may have sold, expired, or the moment for feedback has passed. Don't resurrect stale asks.
5. Skip anything with an existing draft on the thread already (same duplicate check as the
   main pass).

**Drafting the nudge:**
Use this exact template, filling in the recipient's first name:

```
Hello %contact_first_name%,


Following up to find out more about how your clients felt about the condition of the home and the price in relation to that.

Not asking if your guys are the buyers for this property just some data I can bring back to my seller.

Thanks in advance.
```

(Note the double line break after the greeting — that's intentional, matches how the user sends it.) This is the user's own standard feedback-request wording — the follow-up restates the full ask rather than a short one-line nudge, since the recipient may need the context re-surfaced rather than assuming they remember the original email.

**Reporting:** list any follow-ups drafted (recipient/address, how long it's been outstanding)
alongside the rest of the triage report. If nothing qualifies, say so briefly rather than
omitting the check entirely — the user should be able to tell the check ran.

---

## Relationship to the scheduled routine

This skill is for **on-demand, interactive** runs in a session where a Gmail-like MCP tool is already connected. A **cron/cloud routine** doing the same thing on a schedule is a separate setup (see the `schedule` skill) and requires its own MCP connector attached to the routine — the two don't share a connection.
