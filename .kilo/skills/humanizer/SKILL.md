# Humanizer

Humanizer rewrites AI-sounding text so it reads like a person wrote it, without changing what it says. It uses 35 patterns from Wikipedia's ["Signs of AI writing"](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup.

## Usage

Call the skill directly by loading it, then use the patterns when rewriting any prose text.

### The 35 patterns

### Content patterns

| # | Pattern | Before | After |
|---|---------|--------|-------|
| 1 | **Inflated importance and legacy** | "marking a pivotal moment in the evolution of..." | State the fact directly |
| 2 | **Name-dropping to prove importance** | "cited in NYT, BBC, FT, and The Hindu" | Keep only useful, sourced context |
| 3 | **Shallow -ing analysis** | "symbolizing... reflecting... showcasing..." | Keep only what the source supports |
| 4 | **Sales language** | "nestled within the breathtaking region" | "is a town in the Gonder region" |
| 5 | **Vague sources** | "Experts believe it plays a crucial role" | Name a real source or remove the claim |
| 6 | **Formulaic challenges and outlook** | "Despite challenges... continues to thrive" | Keep the facts and remove the sales pitch |

### Language and grammar patterns

| # | Pattern | Before | After |
|---|---------|--------|-------|
| 7 | **Overused AI words** | "Actually... additionally... gated on... quietly... testament... landscape... showcasing" | "also... needs... remain common" |
| 8 | **Avoiding is and are** | "serves as... features... boasts" | "is... has" |
| 9 | **Not X but Y and clipped endings** | "It's not just X, it's Y", "..., no guessing" | State the point directly |
| 10 | **Forced groups of three** | "innovation, inspiration, and insights" | Use the number of items the meaning needs |
| 11 | **Changing names and repeated openings** | "protagonist... main character... hero" or "She noted... She noted... She filed..." | Use one name or merge the repeated sentences |
| 12 | **False from X to Y ranges** | "from the Big Bang to dark matter" | List the topics directly |
| 13 | **Passive voice and missing subjects** | "No configuration file needed" | Name the actor when that helps |

### Style patterns

| # | Pattern | Before | After |
|---|---------|--------|-------|
| 14 | **Em/en dashes** | "institutions—not the people—yet this continues—" | Cut them: periods, commas, colons, or parentheses |
| 15 | **Too much bold text** | "**OKRs**, **KPIs**, **BMC**" | "OKRs, KPIs, BMC" |
| 16 | **Lists with bold mini-headings** | "**Performance:** Performance improved" | Use prose when a list adds no value |
| 17 | **Title case in headings** | "Strategic Negotiations And Partnerships" | "Strategic negotiations and partnerships" |
| 18 | **Emojis** | "🚀 Launch Phase: 💡 Key Insight:" | Remove emojis |
| 19 | **Curly quotes** | `said "the project"` | `said "the project"` |
| 26 | **Too many hyphenated word pairs** | "cross-functional, data-driven, client-facing" | Keep only the hyphens grammar needs |
| 27 | **A fake deeper truth** | "At its core, what matters is..." | State the point directly |
| 28 | **Announcing the next point** | "Let's dive in", or "one thing that bit me" | Start with the content |
| 29 | **A heading repeated below itself** | "## Performance" + "Speed matters." | Let the heading do the work |
| 30 | **Writing about the old version** | "This function was added to replace..." | Describe what it does now |
| 31 | **Forced punchlines and fragments** | "It had no preference. No prior. No nostalgia." | Use natural sentence lengths and specific claims |
| 32 | **Formulaic sayings** | "Symmetry is the language of trust" | State the specific claim |
| 33 | **Fake-candid openings** | "Honestly? It depends..." | State the answer directly |
| 34 | **Answering objections no one raised** | "This isn't mainly about prompt length..." | Remove the unsupported defense and keep any real claim |
| 35 | **Rejecting fake alternatives** | "A tempting option would be to..., but" | Remove the fake option and keep real choices |

### Chatbot patterns

| # | Pattern | Before | After |
|---|---------|--------|-------|
| 20 | **Chatbot text left in the answer** | "I hope this helps! Let me know if..." | Remove it |
| 21 | **Knowledge-limit disclaimers and guesses** | "While details are limited in available sources..." | State what is known or remove the claim |
| 22 | **Overly agreeable tone** | "Great question! You're absolutely right!" | Answer directly |

### Filler and hedging

| # | Pattern | Before | After |
|---|---------|--------|-------|
| 23 | **Filler phrases** | "In order to", "Due to the fact that" | "To", "Because" |
| 24 | **Too many qualifiers** | "could potentially possibly" | "may" |
| 25 | **Generic positive endings** | "The future looks bright" | End with a fact or a sourced plan |

## How to apply

When rewriting text for humanization:

1. Read the original text and understand what it actually says
2. Make a first pass rewriting prose without treating the original structure as fixed
3. Check the draft against the 35 patterns above
4. Rewrite whatever still sounds artificial
5. Do not make up names, numbers, dates, quotes, or citations — keep only what the source supports
6. For technical writing: keep it neutral and plain
7. Leave code, data, frontmatter, and link targets completely untouched

## Key rules to remember

- **Do not make things up.** Facts must come from the source.
- **State things directly.** Avoid "serves as", "features", "boasts", "showcasing", " testament", "landscape", "gated on", "quietly", "additionally", "actually"
- **Use periods, not em-dashes.** Cut the dashes.
- **Remove emojis entirely.**
- **No chatbot phrases.** No "I hope this helps", no "Let me know if", no "Great question"
- **No fake depth.** No "At its core", no "What truly matters is"
- **No announcements.** No "Let's dive in", no "One thing that bit me"
- **End with facts, not optimism.** No "The future looks bright"
- **Avoid bold abuse.** Only bold what genuinely needs emphasis
- **Keep lists short.** No forced groups of three
