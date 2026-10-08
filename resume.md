---
layout: default
title: Resume
permalink: /resume/
---

<div class="bbs-panel mb-8 flex items-center justify-between flex-wrap gap-4">
  <h1 class="font-mono text-2xl text-orange m-0">Jon Roberts<span class="blink-cursor"></span></h1>
  <a href="{{ '/assets/resume.pdf' | relative_url }}" class="font-mono text-aqua hover:text-orange border border-gray px-3 py-1">Download PDF</a>
</div>

<div class="bbs-panel mb-8" markdown="1">

## SUMMARY

Lead software engineer with 15+ years building Ruby on Rails and, more recently, TypeScript systems. I specialize in search, authentication, and high-traffic event platforms, with Nix at work and at home.

</div>

<div class="bbs-panel mb-8" markdown="1">

## SKILLS

Languages
: Ruby, TypeScript, JavaScript, Haskell, SQL, PHP

Frameworks
: Ruby on Rails, Hanami, React, SolidJS

Search
: OpenSearch / Elasticsearch

Auth
: SAML, OAuth2 / PKCE, JWT, SSO, Okta, Doorkeeper

Data
: PostgreSQL, pgvector, Redis, MySQL, CouchDB

Infra
: Nix, Docker, Ansible, AWS, Github Actions

OS
: Linux (NixOS, Debian / Ubuntu, Gentoo), macOS

</div>

<div class="bbs-panel mb-8" markdown="1">

## EXPERIENCE

### Mar 2022 – Present

**Lead Software Engineer**  
*South by Southwest*  
Remote

- Technical lead for a team of 6–10 developers. Build reference architecture the team reuses across projects, review pull requests, and mentor less experienced engineers.
- Designed a search architecture for the SXSW schedule, using OpenSearch (Elasticsearch) as a read-optimized store for the frontend and Postgres as the normalized source of truth.
- Built custom index mappings and denormalized documents across several models, with a presentation layer that shapes results, highlights, and aggregations for faceted search in a React frontend.
- Led a phased migration to unified SSO across SXSW’s Rails and WordPress properties: Clearance sessions with Redis broadcast, a bridge between the .sxsw.com and .sxswedu.com domains, and OAuth2 / PKCE with JWT for the mobile app.
- Rebuilt the attendee recommendations system on pgvector.
- Run development workflows in Jira and GitHub, maintain CI pipelines, Docker and Ansible configuration, and Nix dev environments, and handle AWS infrastructure changes.
- Building MCP tools that let attendees query the schedule through LLM agents.

### Mar 2021 – Mar 2022

**Senior Software Engineer**  
*Proof (formerly Notarize)*  
Remote

- Built SAML single sign-on through Okta for internal staff, mapping Okta groups to role-based access control in the app.
- Integrated with eOriginal’s eVault to securely store the authoritative copies of digitally signed documents.
- Built a CLI tool around a Java PDF library for document processing.
- Refactored flaky and slow rspec+factorybot tests to improve CI reliability.
- Converted / refactored legacy JavaScript to TypeScript.
- Migrated application configuration to AWS Parameter Store as part of the move from Heroku to AWS.

### Oct 2012 – Mar 2021

**Senior Software Engineer**  
*South by Southwest*  
Austin, TX

- Owned SXSW’s core attendee systems: the schedule platform (schedule.sxsw.com), the e-commerce cart and checkout, and the central OAuth / SSO provider used across SXSW’s apps.
- Built cart checkout, coupon redemption, guest-to-user cart merging, and payment processing with ActiveMerchant, plus a coupon management service and a centralized transaction-logging API for payment gateways.
- Built PanelPicker’s public voting and scoring system for session proposals, and messaging, badges, and Facebook login for the SXSW social app.
- Built on-site registration tools: wristband and badge distribution with registration import and deduplication, FileMaker-integrated artist registration, and a volunteer badge printing app using the Shiftboard API.
- Built an image hosting and manipulation service on Thumbor, with client gems that integrated it into SXSW’s Rails apps.

### Sep 2009 – Oct 2012

**Independent Contractor**  
*Various*  
Austin, TX

- Built Rails, Drupal, and WordPress projects for clients including SXSW, Dell, UT Austin, Austin Humane Society, and Scott & White.

### Sep 2008 – Sep 2009

**Lead Developer**  
*Pixeldust Interactive*  
Austin, TX

- Built a 12-language, PDF-generating Drupal site for Johnson Controls, plus CakePHP and WordPress sites for other clients.

### 1998 – 2008

Web / UX designer, and CG artist roles in Austin and Indianapolis.

</div>

<div class="bbs-panel mb-8" markdown="1">


## EDUCATION

### 1999 – 2003

**Savannah College of Art & Design**  
*BFA in Computer Art*  

Studied VFX, compositing, procedural effects, shader programming, design, and a ton of art history.

</div>

<div class="bbs-panel mb-8" markdown="1">


## PROJECTS

[nix-config](https://github.com/emptyflask/nix-config/)
: Multi-host NixOS flake for my desktops and homelab.

[rails-nix](https://github.com/emptyflask/rails-nix)
: Example Rails app using Nix for all dependencies.

other open-source
: Contributed to [nixpkgs](https://github.com/NixOS/nixpkgs/), [dry-rb](https://github.com/dry-rb), [elasticsearch-rails](https://github.com/elastic/elasticsearch-rails), [xmonad-contrib](https://github.com/xmonad/xmonad-contrib), [fmrest-ruby](https://github.com/beezwax/fmrest-ruby), etc.


</div>

<div class="bbs-panel mb-8" markdown="1">

## INTERESTS

Functional programming (Haskell, Elixir, Gleam, Elm, Rust*), cooking, gardening, mushroom foraging, guitar (badly), bicycles, photography.

</div>
