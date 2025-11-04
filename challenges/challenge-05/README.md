# Challenge 05: GitHub Copilot – From Enabled to Effective

## Overview
In previous challenges you explored core GitHub concepts. Here you shift from “Copilot is turned on” to “Copilot is an intentional accelerator for the PetPal platform (pet, activity, accessory microservices + future frontend).” You will (a) verify access, (b) baseline without Copilot, (c) iteratively prototype parts of PetPal with various Copilot interaction modes (Ask / Plan / Edit / Agents), and (d) add lightweight repository guidance via custom instructions (`copilot-instructions.md`, path‑specific instructions, and `AGENTS.md`).

> Source context: See official docs: What is GitHub Copilot (summarized: AI coding assistant providing inline suggestions, chat, terminal help, PR summaries, code review support, and agents) and Custom Instructions (repository‑, path‑, and agent‑level instruction files including `AGENTS.md`).

## Learning Objectives
- Verify Copilot availability & seat status
- Understand difference between baseline manual coding vs assisted flow
- Practice toggling inline suggestions (on/off) and observing effect
- Use Chat modes: Ask (Q&A), Plan (multi‑step breakdown), Edit (transform code), Agents (e.g. `@workspace`) to accelerate PetPal prototyping
- Create repository custom instructions and an initial `AGENTS.md` agent context link (the repo already contains `AGENTS.md` – integrate, don’t duplicate)
- Author a minimal path‑specific instructions example
- Leverage prompt (reusable) or reference attachments for richer answers (optional stretch)

## Prerequisites
- You completed Challenge 02 (intro) & cloned this repository
- A Copilot plan (Free / Pro / Business / Enterprise – Business+ recommended for org policy controls)
- Signed into GitHub within your IDE (VS Code assumed)
- Latest GitHub Copilot & GitHub extension versions installed

## Task Flow (Do in Order)
### Task 1: Access & Environment Verification
1. Open VS Code: Command Palette → “GitHub: Sign in” (if not already). Confirm avatar bottom-left.
2. Visit https://github.com/settings/copilot and confirm seat (or request via org flow if needed).
3. In VS Code Settings search: “Copilot inline” – ensure inline suggestions are enabled (you will toggle later).
4. Run a tiny baseline: In `backend/pet-service/main.py` (or a scratch buffer) manually write (no Copilot):
   - A Pydantic model `Toy` with `id: int`, `name: str`.
   - A FastAPI route `GET /toys` returning a static list.
   Record minutes taken + lines typed.

### Task 2: Baseline vs Assisted – Inline Suggestions
1. Disable inline suggestions temporarily.
2. Add a new endpoint (e.g. `POST /toys` that accepts the model and echoes it) fully manually.
3. Re‑enable inline suggestions; create another endpoint (e.g. `GET /toys/{toy_id}`) letting Copilot suggest.
4. Compare: keystrokes/time & correctness. Hint: Ask Copilot in chat: “Generate FastAPI handler for retrieving toy by id from in‑memory list with graceful 404.”

### Task 3: Chat Modes Exploration (Ask / Plan / Edit / Agents)
Perform each using PetPal context:
| Mode | What to Try | Hint Prompt (adapt, don’t copy blindly) |
|------|-------------|------------------------------------------|
| Ask | Clarify architecture | “Summarize the microservices in this repo and list primary FastAPI app entrypoints.” |
| Plan | Multi-step feature | “Plan adding pagination to pet listing: outline steps, files to touch, tests.” |
| Edit | Transform code | Select a route → “Add input validation & 422 error example response.” |
| Agents (@workspace) | Repo-wide reasoning | “@workspace Where should I add a shared Pydantic base model for timestamps?” |
| Agents (@terminal if available) | Command help | “@terminal Show how to curl the pets endpoint filtering by species.” |
| Agents (code review) | (Optional) | Open a diff and ask: “Suggest improvements & docstring updates.” |

Capture which mode produced the most leverage for this codebase and why.

### Task 4: Repository Custom Instructions & Agent Context
Objective: Provide consistent guidance so Copilot produces higher-fidelity PetPal suggestions.
1. Create (if not existing) `.github/` directory.
2. Add `.github/copilot-instructions.md` with HIGH-LEVEL info only (avoid secrets, avoid task-specific content). Include:
   - Short description of PetPal + microservices.
   - Tech stack (FastAPI, Pydantic, tests via pytest).
   - Build/test quick path (e.g., how to run a single service locally).
   - Conventions (refer to `AGENTS.md` instead of duplicating agent rules).
3. Path-Specific Instructions (example):
   - Create `.github/instructions/pets.instructions.md` applying to `backend/pet-service/**/*.py`.
   - Frontmatter example:
     ```
     ---
     applyTo: "backend/pet-service/**/*.py"
     ---
     Prefer dependency-injected database handles; ensure 404 handling returns JSON {"detail":...}.
     ```
4. Agent Instructions:
   - Review existing `AGENTS.md` in repo; incorporate any missing guidelines into the new `copilot-instructions.md` instead of duplicating conversely.
   - (Optional) Add a targeted `AGENTS.md` section for “Pet data normalization rules” if genuinely reusable.
5. Validate: Open Copilot Chat → run a prompt referencing a pet file → expand References to confirm `copilot-instructions.md` is used.

### Task 5: Prompt / Reusable Context (Stretch)
1. Enable prompt files (VS Code setting `chat.promptFiles`: true) if exploring advanced flows.
2. Create `.github/prompts/PET_ENDPOINT.prompt.md` with a reusable pattern:
   - Purpose: “Generate FastAPI CRUD route skeleton + basic tests for resource X.”
   - Include placeholder tokens (e.g., `<ResourceName>` instructions) and file references.
3. Use it in Chat by attaching the prompt and providing `<ResourceName=Accessory>`.

### Task 6: Lightweight Prototyping with Copilot (Pets → Activities → Accessories)
Using hints only (don’t seek full solution):
1. Ask: “Generate a Pydantic model for Pet with species, age, created_at (ISO).”
2. Ask Plan mode to outline adding filtering by species & min_age.
3. Use Edit mode: select route → “Refactor to inject DB session parameter.”
4. Use Ask: “Suggest a simple React component (typescript) listing pets with loading + error state.”
5. Evaluate which prompts produced: (a) correct types, (b) minimal post-fix edits.

### Task 7: Reflection & Metrics
Capture (brief notes):
- Time manual vs assisted for similar endpoints
- Most helpful Copilot mode & why
- Any hallucinations or unsafe suggestions (record & refine instructions to mitigate)
- One improvement to `copilot-instructions.md` discovered through usage

## Success Criteria (Check All)
- [ ] Verified Copilot seat & IDE sign‑in
- [ ] Baseline manual endpoint created (timed)
- [ ] Inline suggestions compared (off vs on) with observations noted
- [ ] Used Ask, Plan, Edit, and at least one Agent mode meaningfully
- [ ] Added `.github/copilot-instructions.md` (non-task-specific, high signal)
- [ ] Added one path-specific instructions file
- [ ] Confirmed instructions appear in Chat References
- [ ] Prototype endpoints/models improved with Copilot assistance
- [ ] Reflection notes captured

## Hints (No Full Solutions)
| Scenario | Hint Style Prompt | What to Watch |
|----------|-------------------|---------------|
| New model | “Create Pydantic model Pet (fields: id:int, name:str, species:Literal[...] age:int, created_at: datetime) with example config.” | Validate imports & timezone handling |
| CRUD route | “FastAPI route POST /pets storing to in-memory list; return 201 & object with generated id.” | Ensure proper status code |
| Validation | “Add 422 example response to existing route docstring for missing name.” | OpenAPI doc update |
| Pagination | “Plan adding limit/offset to GET /pets; list code changes only.” | Separation of concerns |
| React list | “Generate React TS component PetList fetching /pets with useEffect + loading/error states.” | Avoid any hardcoded internal URLs |
| Test | “Pytest example for GET /pets returning list with monkeypatched repo layer.” | Keep test isolated |

Refine poor suggestions by: (a) adding constraints (“keep function pure”), (b) referencing files (`#file:backend/pet-service/main.py`), (c) tightening style (“use Pydantic BaseModel”).

## Custom Instructions Quick Reference
Type | Location | Purpose
-----|----------|--------
Repository-wide | `.github/copilot-instructions.md` | Global context & build/test conventions
Path-specific | `.github/instructions/*.instructions.md` | Domain or layer norms (e.g. pet-service)
Agent | `AGENTS.md` (nearest) | Higher-level behavioral guidance for agents
Prompt file (stretch) | `.github/prompts/*.prompt.md` | Reusable long-form task templates

Keep them: concise, non-conflicting, void of secrets, updated when conventions shift.

## Good vs Weak Instruction Examples
| Weak | Improved |
|------|----------|
| “We use FastAPI.” | “Use FastAPI; all new routes return JSON errors: {"detail": str}. Prefer Pydantic models for responses.” |
| “Add tests.” | “All new endpoints require at least one pytest function asserting 2xx and one failure path (404/422).” |

## Additional Resources
- What is GitHub Copilot: https://docs.github.com/en/copilot/get-started/what-is-github-copilot
- Custom Instructions: (repository & path-specific) https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions
- Response customization overview: https://docs.github.com/en/copilot/concepts/prompting/response-customization
- Prompt files (preview): VS Code docs (search “Copilot prompt files”)

## Reflection Template (Optional)
```
Baseline manual endpoint time: X min
Assisted endpoint time: Y min
Most useful mode & why:
Hallucination examples (if any):
Instruction file tweak needed:
Next improvement target:
```

## Solution
You can review guided solution notes after attempting: [Solution Steps](/solutions/challenge-05/README.md)

> Do NOT peek until you’ve completed reflection. The value is in deliberate comparison, not the final code.