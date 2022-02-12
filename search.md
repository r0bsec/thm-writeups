---
title: Search
permalink: /thm-writeups/search/
searchExclude: true
---

<div id="search-container">
    <input type="text" id="search-input" disabled class="form-control">
    <ul id="search-results-container"></ul>
</div>

<script src="https://unpkg.com/simple-jekyll-search@latest/dest/simple-jekyll-search.min.js"></script>

<script>
    async function SetupSearch() {
        var searchInput = document.getElementById('search-input');
        var querySearchString = decodeURI(window.location.search.substr(1)).replace("+"," ");
        var searchString = searchInput.value;
        if (querySearchString && !searchString) {
            searchString = querySearchString;
            searchInput.value = searchString;
        }

        {% comment %} //the delayed placeholder assignment is to stop it glitching when populated from querystring {% endcomment %}
        if (!searchString) searchInput.placeholder="Start typing to quick search..."

        let response = await fetch("{{ site.baseurl }}/search.json");
        if (!response.ok) return;
        var searchData = await response.json();

        var simpleJekyllSearch=SimpleJekyllSearch({
            searchInput: searchInput,
            resultsContainer: document.getElementById('search-results-container'),
            searchResultTemplate: '<li><strong><a href="{{ site.url }}{url}">{title}</a></strong><br>&nbsp;&nbsp;&nbsp;{subtitle}</li>',
            // json: '{{ site.baseurl }}/search.json'
            json: searchData
            // ,fuzzy: true,
        });
        {% comment %} //thanks: https://github.com/christian-fei/Simple-Jekyll-Search/issues/98#issuecomment-374761531 {% endcomment %}
        if (searchString) simpleJekyllSearch.search(searchString);
        searchInput.disabled=false;
        searchInput.focus();
    }
    SetupSearch();
</script>