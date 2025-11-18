# Challenge 05: GitHub Copilot – From Enabled to Effective

## Overview
So far we have used GitHub Copilot to brainstorm ideas, analyze business context, create Issues and iterativelly work on Product Requirements Document. In fact we have used few tools such as GitHub MCP Server. Now it is time to expand on this and see how will GitHub Copilot help us with all remaining challenges.

## Copilot basics

### Model selection
- Auto - let Copilot decide what model to use, if it selects premium model than 1x gets discounted to 0.9x
- Base models do not consume premium requests (0x)
  - Use it for simple text tasks and searches. 
  - As of October 2025 I prefer GPT-5-mini
- Premium models consume premium requests, most often one per request (1x)
  - 10x models if available work just slightly better and are order of magnitude more expensive and slow, typically you will not prefer those
  - Switch model when Copilot is not able to move beyond some issue or after previous one finished so you get second opinion
  - As of November 2025 we would usually combine GPT-5.1-Codex and Claude Sonnet 4.5 for coding and GPT-5.1 or Gemini 2.5 Pro for document writing and brainstorming
  - 0.33x models are faster and save few requests, but quality is lower (we would usually use 1x model for everything except for simple tasks with GPT-5-mini)  

### Codebase Search
Ask Copilot to search and understand your code. Copilot will automatically use search tools, but if you want to be very explicit, you can reference tool with `#`, for example `#codebase` to explicitly search codebase. You also use this symbol to put specific file into context - either using mouse or `#myfile.py`.

```markdown
How are collections in database created in our project? Point me to specific libraries and sections of code.
```

Experiment with different models selection and see their different outputs and approaches.

### Generating documentation
Create new file MY_NEW_DOCS.md, add it to context (drag and drop or using `#`) and let's iterativelly ask for documentation. After each step, if you are satisfied, click Keep so you can track differences.

- `Look at challenged folder and create list of challanges with two senteces per each, capture main topic. Use differen Unicode emoji for each.`
- `Look at my backend folder and check for environmental variables we are using for configuration. Create Markdown table with list with simple description and add it to #MY_NEW_DOCS.md.`
- `Services in our backend use Pydantic models to define various data schemas. I want to draw data model of our application using mermaid, add those to #MY_NEW_DOCS.md.`

You can use Markdown preview (CTRL+SHIFT+P and search for it) to see diagram rendered.

## Web Search and Fetch

Ask questions about current information:

Try without tools using just model knowledge.
```
When did Microsoft released Microsoft Agent Framework SDK for Python and what is current version? Do NOT use any tools.
```

If you have specific documentation in mind, you can just reference it here (eg. llms.txt or llms-full.txt, see)

```
When did Microsoft released Microsoft Agent Framework SDK for Python and what is current version?
#fetch 
https://github.com/microsoft/agent-framework/releases
https://learn.microsoft.com/en-us/agent-framework/overview/agent-framework-overview

#githubRepo microsoft/agent-framework
```

You can also add web search tools such as `Tavily`.

## Agent Mode

## Customize Copilot to fit our project needs

## Adding MCP tools

## Success criteria

- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
- [ ] 
