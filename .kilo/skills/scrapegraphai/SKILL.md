---
name: scrapegraphai
description: Web scraping skill using ScrapeGraphAI - scrape websites, search engines, and extract structured data using LLM-powered pipelines. Use for research, data collection, and fetching web content that would normally get blocked.
---

# ScrapeGraphAI Skill

Use ScrapeGraphAI for web scraping and data extraction tasks.

## When to Use

- Researching device-specific kernel information
- Finding vendor blobs or device tree repositories
- Extracting data from websites that block simple crawlers
- Multi-page data collection tasks
- Building knowledge bases from web sources

## Installation

```bash
pip install scrapegraphai playwright && playwright install
```

## Quick Usage

```python
from scrapegraphai.graphs import SmartScraperGraph

graph_config = {
    "llm": {"model": "openai/gpt-4o-mini", "api_key": "YOUR_KEY"},
    "verbose": True,
    "headless": True,
}

smart_scraper = SmartScraperGraph(
    prompt="Extract all repository names, URLs, and descriptions",
    source="https://github.com/LineageOS/android_kernel_oneplus_sm8550",
    config=graph_config
)

result = smart_scraper.run()
```

## Available Pipelines

| Pipeline | Use Case |
|----------|----------|
| `SmartScraperGraph` | Single page extraction |
| `SearchGraph` | Search engine results |
| `ScriptCreatorGraph` | Generate scraping scripts |

## Example Prompts

**Find device trees:**
```
Extract all device tree repository names, their GitHub URLs, and the SoC/chipset they support
```

**Find kernel sources:**
```
List all kernel source repositories mentioned, including the branch names and device codenames
```

**Research vendor blobs:**
```
Extract all vendor blob repository URLs and the devices/chipsets they support
```

## Tips

- Always use descriptive prompts
- For GitHub, include specific fields you want extracted
- Set `headless=True` for faster scraping
- Use `verbose=True` to debug issues
