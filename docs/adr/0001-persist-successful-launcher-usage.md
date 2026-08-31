# Persist successful launcher usage counts

The Phase 7 launcher records successful main-command launches by stable
desktop-entry ID in a versioned QE-owned `launcher-usage.json` XDG state file
whose `entries` object maps IDs to `launchCount`, retaining at most 512 records.
Usage ranks empty-query results, while search relevance remains primary for
non-empty queries; terminal entries are excluded from v1. Persistence failure
does not fail a launch and is reported as a bounded diagnostic.
