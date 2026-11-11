---
layout: default
title: Home
permalink: /
---

<section class="bbs-panel mb-8" markdown="true">

I'm Jon, this is my corner of the internet for random things that don't really belong elsewhere.

</section>

<h2 class="text-xl text-orange mb-4">Recent posts<span class="blink-cursor"></span></h2>
<ul class="space-y-6">
  {% for post in site.posts limit: 5 %}
    {% assign thumb = post.thumbnail | default: post.image %}
    {% assign summary = post.description | default: post.excerpt | strip_html | normalize_whitespace | truncatewords: 30 %}
    <li class="bbs-panel flex items-start gap-4">
      {% if thumb %}
        <a href="{{ post.url | relative_url }}" class="block shrink-0 w-28 sm:w-56">
          <img src="{{ thumb | relative_url }}" alt="" loading="lazy" class="w-full h-auto">
        </a>
      {% endif %}
      <div>
        <a href="{{ post.url | relative_url }}" class="font-mono text-lg text-fg0 hover:text-orange">{{ post.title }}</a>
        <p class="font-mono text-sm text-gray">{{ post.date | date: "%Y-%m-%d" }}</p>
        <p class="font-mono text-sm mt-2">{{ summary }}</p>
      </div>
    </li>
  {% endfor %}
</ul>
