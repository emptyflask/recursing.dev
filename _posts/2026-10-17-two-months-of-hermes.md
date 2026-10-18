---
title: "Two months of Hermes"
tags: [ai, homelab]
---

The first time I attempted to build an agent was back in July, when OpenClaw
was getting a lot of attention. It never really got off the ground, as I felt
like I was fighting against the intent of the developers by wanting to run it
as a system-level service on my homelab server (an old laptop in the basement,
running NixOS of course). [Telegram](https://telegram.org/) integration just
refused to work, and so I gave up after a few days.

Only about a week later, I noticed
[Hermes](https://hermes-agent.nousresearch.com/), and notably their (tier 2)
support for Nix installations, and decided to give agents another shot. Even
Hermes seems to be pushing users towards a desktop app, instead of an always-on
service I could interact with from anywhere, but at least they have
documentation on setting up the latter. No need
to go over the installation details, though it did finally nudge me enough to
properly set up encrypted credentials via
[agenix](https://github.com/ryantm/agenix), which was one of the reasons I
hadn't published my [systems
configuration](https://github.com/emptyflask/nix-config) until now.

## Models, Features

For the main model, I picked `deepseek-v4-flash-0731` through
[Openrouter](https://openrouter.ai/), since it seems to punch way above its
weight. I'm sure the flagship models could run circles around it, but as you'll
see, I'm not exactly using it to write mission-critical programs. I've got
Claude Code for that. I only give it a budget of a few dollars per month.

I had just finished reading/listening to the first two books of Adrian
Tchaikovsky's [Children of Time
series](https://www.goodreads.com/series/247630-children-of-time) and so gave
the agent the `SOUL.md` of Avrana Kern, an AI entity copied from the mind of a
terraformer with a god complex, which now lives on thanks to a biological
computer built with a colony of ants. Amazingly, she still comes across as
helpful, and as far as I can tell she isn't plotting against me. Another good
reason to stay off of the expensive models, I suppose.

I have it using [Firecrawl](https://www.firecrawl.dev/) for search and web
scraping, [Hindsight](https://ui.hindsight.vectorize.io/login) for memory. I
suspect that Hindsight is overkill for my purposes, but it's cheap enough that
I might as well just use it.

I mentioned earlier that I wanted to be able to use it from anywhere, and
that's where Telegram comes in. I can send messages to the agent from my phone
or desktop, and the same chat session exists in both places. I don't even have
to use Wireguard.

## But what does it do?

This was the largest question I had at the beginning. I never really felt a
need for a personal agent, living or synthetic. I had to look for ideas.

As for the agent's actual usefulness, the most common thing I do with it is
treat it like a glorified cron manager. I ask it to report headlines in the
morning from Reddit, Hacker News, and a few other sources, based on my
interests. I have it suggest meals from my recipe database each week. It sets
reminders for various things that I don't want to think about enough to add to
my calendar, and nags me to get some exercise. I had it write a script to watch
for dogs that were recently added to three different adoption sites.

The coolest ability though is that I connected it to an [Obsidian vault MCP
server](https://github.com/bitbonsai/mcpvault) that runs against a self-hosted
headless livesync instance of my Obsidian notes. Any changes to my notes are
instantly synced through CouchDB across all devices, one of them being my
server laptop. So the agent can read and write notes. I can give it a URL to a
recipe and have it copied into a template and filed away in the right place. I
don't even have to scroll down through pages of opinions and product
recommendations, I just let the agent find the relevant data.

It's also good at keeping the rest of my Obsidian vault organized -- like
concatenating old daily to-do lists, notes, etc. into monthly and yearly
digests.

It's far from perfect, though. Multiple times it seems to forget that a
conversation happened a week ago, not yesterday. Or it recommends the same five
meals for multiple weeks in a row. But it does appear to learn from mistakes,
and refines itself over time.

It will be interesting to see what it does over the next year and beyond, if
I'm still using it, or if something new comes around.
