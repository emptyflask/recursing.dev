---
title: "One search box, nine indices"
tags: [rails, opensearch]
description: How search works on the SXSW schedule, queries across multiple model types with aggregations and conversions.
---

The search box on [schedule.sxsw.com](https://schedule.sxsw.com) has one job that turns out to be several. Someone types "jackson" on their phone while standing in line, and the results need to include the panel with a Jackson on it, the band, the film, the speaker's profile, and maybe a venue, ranked against each other, with filter counts that make sense, and without leaking anything the festival hasn't announced yet. It's the most interesting part of the schedule app.

## One query instead of nine

There are nine searchable models: artists, attendees, brands, events, exhibitors, films, people, music fest presenters, and venues. Each one has its own index through Searchkick, with its own analyzers and mappings. The obvious approach would be nine searches and a merge in Ruby, but scores from separate queries aren't comparable, and pagination and facet counts get ugly fast.

Instead, `Search::Query` builds one raw OpenSearch body and hands it to `Searchkick.search(body:, models:, load: false)`, which runs it across every index at once. Each model contributes its own piece through a `search_query` class method, and the query object collects them into a `dis_max`:

```ruby
{
  query: {
    bool: {
      must: [{ dis_max: { tie_breaker: 0.7, boost: 1.2, queries: queries } }],
      filter: [{ bool: { must: [{ term: { year: @year } }, *@filters[:top]], must_not: ... } }]
    }
  },
  post_filter: { bool: { filter: filters } },
  aggs: aggregations,
  min_score: 1
}
```

`dis_max` takes the best-scoring clause for each document and adds 70% of the others, so a film that matches on title doesn't get outscored by an event that matches weakly on six fields. Each model's clause is itself two `multi_match` queries: an exact one with `operator: 'and'` and a boost of 5, and a fuzzy one (`fuzziness: 'AUTO:4,8'`, `prefix_length: 2`) so typos still land somewhere. `min_score: 1` cuts off the long tail of accidental fuzzy matches.

The `must_not` block is where festival logistics show up in the query. Screenings and showcases without a date are hidden, since a film screening with no time attached isn't useful to anyone, and in preview mode (before the full schedule is out) they're hidden entirely.

## Aggregations that don't eat themselves

Filters are where the query gets interesting. The sidebar shows facets like Format, Theme, Genre, Venue, and Date, each with counts. If you pick "Workshop" under Format, the results should narrow, but the Format facet should still show you how many panels there are, otherwise the only option left in the list is the one you already picked.

The standard trick is `post_filter`, which applies after aggregations run, so the hits are filtered but the facets aren't. That alone overcorrects, though: now picking a venue doesn't change the counts under Format at all. Each aggregation needs to respect every filter *except* the ones on its own field. That's what `build_filtered_agg` does:

```ruby
def build_filtered_agg(field:, filters:, size: 20, order: { _key: 'asc' }, meta: {}, additional_filter: nil, format: nil)
  {
    filter: {
      bool: {
        must: filters.reject {|f| f.dig(:terms, field.to_sym) }
                     .push(additional_filter)
                     .compact
      }
    },
    aggs: {
      field.to_sym => {
        terms: { field: field, size: size, order: order, format: format }.compact,
        meta: meta
      }
    }
  }
end

def format_aggs(filters: [])
  {
    format: build_filtered_agg(
      field: 'formats',
      filters: filters,
      size: 200,
      order: { _key: 'asc' },
      meta: { name: 'Formats', model: 'event', group: 'Conferences' },
      additional_filter: {
        bool: {
          must: [
            { term: { type: 'event' } },
            { terms: { event_type: conference_event_types } }
          ]
        }
      }
    )
  }
end
```

Every facet is a filter aggregation wrapping a terms aggregation, with its own field's filter removed and an `additional_filter` that scopes it (conference formats only count conference events, for example). Events alone define 20 of these, and every model in the search adds its own to the same body, so a single request returns hits and every facet count in one round trip.

The `meta` hash is how the frontend knows what to draw. It carries the display name, the group the facet belongs in ("Conferences", "Film & TV Festival"), labels for boolean buckets, and whether it starts open. The filter sidebar has no hardcoded list of facets; it renders whatever comes back.

Filters themselves travel as a compact string, `event/format:Panel|Workshop;venue:Hilton`, and `Search::TransformFilters` groups them by model. Filters with no model go under `:top` and apply in the main query, so they shape the facets too. Model-scoped filters go into `post_filter`.

## The results decorator

Since the search runs with `load: false`, nothing touches ActiveRecord. The raw hits go to `Search::Results`, which is where most of the business rules live.

It strips fields the festival isn't ready to show. The index has venue and time data well before we're allowed to publish it, so `filtered` drops `venue`, `venue_root`, `date`, `start_time`, and `end_time` from each hit whenever preview mode is on or those features are disabled. It also changes the grouping: an events-only search normally groups by time, and falls back to alphabetical when there are no times to group by. I like having this in one place. The frontend never receives the data, so there's nothing for it to accidentally render.

It also figures out what each hit means to the current user. Favorites have different types depending on the record (a showcase event favorites as an "entity", attendees key on `uid`), and events get a `reserved` flag. That last one was an N+1 waiting to happen, so it collects every `reservable_id` on the page and checks them in a single query against `Reservation`.

Aggregations come back from OpenSearch nested inside the filter aggs, so `aggregation_leaf_nodes` walks the tree and pulls out anything with a `buckets` key, then `Search::Results::Aggregation` normalizes each one into the shape the frontend expects.

Highlights pass straight through. The query asks for up to three fragments per field wrapped in `<span class='highlight'>`, except for `name`, which uses the plain highlighter with no fragmenter. Before that change, long session titles came back chopped into pieces. On the frontend, the `Highlighted` component escapes every `<` and `>` in the fragment and then un-escapes exactly the highlight span, so the only HTML that survives is the HTML we put there.

## Ranking by what people click

The most recent work, was using click data for ranking. Searchjoy had been installed for a while and logging every search and click, but the two ends were never connected. The worker that rolls clicks up into each record's `conversions` field had never been scheduled, and Searchkick's built-in conversion boosting only applies when you use its query DSL. We hand-build raw bodies, so it was never going to kick in on its own.

```ruby
class ConversionBoost
  def rescore
    {
      window_size: WINDOW_SIZE,
      query: {
        rescore_query: { bool: { should: [per_query, popularity]} },
        query_weight: QUERY_WEIGHT,
        rescore_query_weight: RESCORE_QUERY_WEIGHT
      }
    }
  end

  private

  def per_query
    {
      nested: {
        path: 'conversions',
        score_mode: 'sum',
        boost: PER_QUERY_WEIGHT,
        query: {
          function_score: {
            query: { term: { 'conversions.query': @term } },
            field_value_factor: {
              field: 'conversions.count',
              modifier: 'ln1p',
              missing: 0
            },
            boost_mode: 'replace'
          }
        }
      }
    }
  end

  def popularity
    {
      function_score: {
        query: { match_all: {} },
        boost: POPULARITY_WEIGHT,
        field_value_factor: {
          field: 'conversions_count',
          modifier: 'ln1p',
          factor: POPULARITY_FACTOR,
          missing: 0
        },
        boost_mode: 'replace'
      }
    }
  end
end
```

`Search::ConversionBoost` adds two scores: a per-query boost for records people clicked after searching this exact term, and a smaller popularity nudge based on total clicks, both dampened by taking the natural logarithm of their counts so one runaway term can't take over. They go into a `rescore` block instead of a `should` clause. Rescore runs after `min_score` has already picked the documents, so it can reorder results but can't add any. As a `should` clause, a popular record that scraped by on an accidental one-letter fuzzy match could have climbed over the cutoff. The cost is that `_explain` doesn't cover the rescore phase, which makes debugging rankings more annoying. It's behind a Flipper flag while we tune the weights.

While cleaning up the field list for that work, I also found the panelists field had a double metaphone subfield in the search fields. Phonetic matching is great for names and terrible for topics: "exchange" encodes to the same thing as "Jackson." I measured 135 false matches across 26 common terms, so it's out of the search fields now.

## TLDR

There's a lot going on, and faceted searches can get surprisingly complex. Libraries like Searchkick can make some things easier, like handling background reindexing, but you quickly lose the conveniences once you start to stray from the simple path.
