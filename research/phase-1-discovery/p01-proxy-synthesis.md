# P01 (proxy) — "M" (husband of researcher)

> **Proxy data.** Interview conducted with M's wife answering on his behalf. Data is directionally useful but should be re-verified with M directly before locking scope. Tag all insights derived from this session as `[proxy]` in the team report.

## Meta

- **Date:** 2026-04-19
- **Duration:** ~25 min (short-form proxy format)
- **Facilitator:** Claude (acting as Jordan)
- **Notetaker:** N/A (proxy session, live transcribed)
- **Participant type:** Coach (hobby)
- **Recording:** N/A — text interview

## Demographics

- **Location:** Los Altos, CA
- **Coaching identity:** Hobby, not income
- **Other context:** Runs a monthly golf friends' group (18 holes, not-for-profit)
- **Students:**
  - Ethan, his 7-year-old son — 5 days/week, 10 min/day, backyard
  - Adult friends with prior golf experience — ~monthly, informal, free
- **Existing equipment:** Backyard net + launch-monitor-style tracker with metrics
- **Ethan context:** Competes in US Kids tournaments; generally doing well; both weekend days spent at tournaments

## 3-bullet TL;DR

- **He specifically asked his wife to build this.** That's the biggest signal of the interview — the product idea originated from him, not from us inventing a need.
- **The problem is not analysis, it's organization.** He doesn't currently record video at all because the friction (record → find later → compare) is too high. Google Photos is where everything lives, and it's unusable: mixed with family content, no way to annotate, no way to compare.
- **Review happens AFTER the session, not during.** He runs a 10-min training block, then reviews with Ethan. Real-time metrics on screen is NOT the job.

## Direct quotes (proxy-reported)

> "He has a plan. Usually from Ethan's last tournament performance."

> "Ethan is not happy. Not practicing seriously." *(when a session goes badly)*

> "It's more for him to look at and he will explain it to Ethan." *(on the tracker)*

> "Google Photos has all other videos/photos. It's hard to find all the golf videos and compare. And also we can't take notes on Google Photos."

> "Organized data so it's easy to give advice and learn about his improvement over time." *(wishlist)*

> "He asked for this app. That was his idea."

## Behavior patterns observed

- **How M decides what to work on:** Plans each session against Ethan's most recent tournament performance. Not gut, not tracker data alone — tournament is the source of truth.
- **Role of phone in current practice:** Not recording today. When he does record ad-hoc, it lands in Google Photos where it's effectively lost.
- **How feedback is delivered:** Coach consumes raw data (tracker, any video), translates it verbally for Ethan. Ethan doesn't directly consume metrics.
- **Timing of review:** Strictly after the 10-min practice block, not during.
- **Student dynamic:** Ethan's motivation is the hidden variable — bad session = disengaged, not technical.

## Pain points voiced

1. **Cannot find specific golf videos** — they're buried in a Google Photos stream dominated by family content.
2. **Cannot annotate videos** — no way to note "the good one," "this was before the tournament," "work on this."
3. **Cannot compare videos** — no side-by-side, no timeline, no "show me today vs. last month."
4. **Recording friction is so high he mostly doesn't record** — the intent exists but the current toolchain kills it.

## Wishes / unsolicited ideas

1. Organized video library
2. Easy to give advice (annotations implied)
3. Learn about improvement over time (trends / comparison)

## Implications for our product

### Major persona shift

- **OLD:** Annie, casual golfer at the driving range, films own swings, wants analysis.
- **NEW:** M, dad/hobby-coach, coaches his competitive 7yo son daily at home + adult friends monthly. Kid is the subject; coach is the user.

### Jobs-to-be-done (revised)

1. Capture swings quickly during a 10-min backyard block (low-friction)
2. Automatically organize by player / session / date / tournament (not by phone gallery)
3. Annotate specific swings ("this was his best," "hip slides here," "after tournament loss")
4. Compare any two swings side-by-side or across a timeline
5. Show improvement over time, ideally keyed to tournament events

### Scope impact on PRD

| Original MVP item | Decision | Why |
|---|---|---|
| Self-recording flow (Annie tripod) | **Keep** | Still useful — dad films Ethan from stand |
| Sun-glare / gloved-hand UX principle | **Drop** | Backyard is the context, not outdoor range |
| "Plain English" metric coaching copy | **Demote** | Coach consumes raw data; student not the reader |
| Tag player (Me / Friend) | **Keep, reframe** | Tag is Ethan / adult friend name |
| Club tag | **Keep** | Still useful context |
| Tempo / rotation / head-stability metrics | **Keep** | Useful for coach to interpret |
| Session history | **Upgrade to Library** | Library is now a PRIMARY feature, not secondary |
| Compare two swings | **Keep, promote** | Higher priority — central to the wishlist |
| **Annotations / notes on swings** | **ADD** | Not in MVP today; explicitly requested |
| **Tournament events + session tagging** | **ADD** | He plans from last tournament — first-class concept |
| **Trend-over-time view** | **Promote** | Was a small trend chart; now a headline feature |
| **Tracker data import (future)** | **ADD to v1.1** | Existing tracker is part of his workflow; bridging video + tracker adds value |
| Friend account sharing | **Stay deferred** | Not relevant here |
| Coach marketplace / payments | **Stay out** | Hobby, not-for-profit |

### Impact on UX

- Screen priorities: **Library first**, Capture second, Session review third. (Was Capture-first in the original design.)
- Annotation UI is a net-new feature area.
- Tournament timeline view is a net-new concept.
- Kid-friendly "watch yourself" mode (for showing Ethan post-session) is a secondary mode worth sketching.

### Impact on HLD / LLD

- Architecture decisions (Flutter, on-device, Drift) remain sound — no change.
- Data model needs: `tournaments`, `annotations`, link from `sessions` to `tournaments`.
- Storage: videos are the product; tighten compression defaults, make delete intentional.
- Backyard environment means Wi-Fi is probably available — cloud sync moves up in v1.1 priority (backup the library for peace of mind).

## Open questions (to chase in a real interview with M)

1. How does he currently record, the rare times he does? Phone gallery, screen record of tracker, other?
2. Would he want Ethan to see the annotated video, or are annotations for his eyes only?
3. Which tracker does he use? (Determines v1.1 import scope — Rapsodo / Garmin R10 / SkyTrak all expose data differently.)
4. What does he currently do on tournament days — record matches, keep notes, something else? (Could be a feature area.)
5. For the monthly adult-friend sessions — is the same tool useful, or are those so different they don't need our help?
6. What device does he use? Assumed Android given family; needs confirmation.
7. Is Ethan's reaction to seeing himself on video something he'd describe as helpful or unhelpful? (Motivation-adjacent.)

## Red flags

- **Proxy bias.** The wife is the researcher's respondent AND the product's builder. Proxy data skews toward what the builder wants to hear. Every insight above needs a "he actually confirmed this" check.
- **N=1.** Even once M is interviewed directly, we have one real user. Still need the Phase 1 sample (6 interviews) to avoid over-fitting to this household's specifics — BUT we should now recruit hobby-coaches / parent-coaches, not recreational range golfers.
- **Sample skew risk.** Rebuilding recruitment around parent-coaches of competitive young golfers is a narrow pool. May need to widen to "anyone who coaches someone else regularly, formal or not."

## Recommended next steps

1. **Re-interview M directly** using the coach script. ~30 min with him, verify every claim marked `[proxy]` in this doc.
2. **Revise PRD** around the coach persona, using this doc + M's interview as grounding. Keep the existing HLD/LLD as-is where possible.
3. **Re-spec recruitment** for Phase 1 remaining interviews — target 5 more hobby/parent coaches, not recreational golfers.
4. **Sketch Library + Annotation UX** (Lin) — two new feature areas that didn't exist in the original design.
