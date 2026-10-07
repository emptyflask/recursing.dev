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
    <li class="bbs-panel">
      <a href="{{ post.url | relative_url }}" class="font-mono text-lg text-fg0 hover:text-orange">{{ post.title }}</a>
      <p class="font-mono text-sm text-gray">{{ post.date | date: "%Y-%m-%d" }}</p>
    </li>
  {% endfor %}
</ul>
