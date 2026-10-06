---
layout: default
title: Home
permalink: /
---

<section class="bbs-panel mb-8">
  <p class="font-mono text-fg1">
    Hi, I'm Jon. This is recursing.dev — placeholder bio copy, replace this
    with the real thing.
  </p>
</section>

<h2 class="font-mono text-xl text-orange mb-4">Recent posts<span class="blink-cursor"></span></h2>
<ul class="space-y-6">
  {% for post in site.posts limit: 5 %}
    <li class="bbs-panel">
      <a href="{{ post.url | relative_url }}" class="font-mono text-lg text-fg0 hover:text-orange">{{ post.title }}</a>
      <p class="font-mono text-sm text-gray">{{ post.date | date: "%Y-%m-%d" }}</p>
    </li>
  {% endfor %}
</ul>
