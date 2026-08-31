set shell := ["zsh", "-uo", "pipefail", "-c"]
set unstable := true

# Developer ID Application: Jurre-Jan Smit. Hardcoded — see the note in project.yml.

identity := "72B6E55BE646D0664EF83C986B55B8F6D58BC2B6"
team := "KA6433FU8U"

# One Apple ID, one stored credential. Created once with
# `xcrun notarytool store-credentials utt-notary`; shared with utt rather than
# duplicated, because a second profile would hold the same app-specific password.

notary := "utt-notary"
built := ".build/Build/Products/Debug/continuity.app"
archive_path := "release/continuity.xcarchive"
export_dir := "release/export"
export_options := "release/ExportOptions.plist"

# project.yml is the one place the version is written; everything downstream —
# the zip's name, the appcast, the download link — reads it from here, so a
# shipped file can always be traced back to a build.

version := `sed -n 's/.*MARKETING_VERSION: *"\(.*\)".*/\1/p' project.yml | head -1`

# Sparkle's appcast keeps every version it can still see, so the zip is named per
# version too — an overwritten continuity.zip would silently rewrite an old update.

zip_path := export_dir + "/continuity-" + version + ".zip"

# Kept across releases, unlike export_dir: the appcast generator needs the previous
# feed and its archives next to each other to carry old entries forward.

appcast_dir := "release/appcast"
repo_url := "https://github.com/doublej/continuity"
releases_url := repo_url + "/releases"
xcflags := "-project Continuity.xcodeproj -derivedDataPath .build -skipMacroValidation -skipPackagePluginValidation"

default:
    @just --list
    @echo ''
    @echo "branch: $(git branch --show-current 2>/dev/null || echo 'n/a')"

[group('setup')]
install:
    @command -v xcodegen >/dev/null || echo 'warn: brew install xcodegen'
    @command -v swiftlint >/dev/null || echo 'warn: brew install swiftlint'
    just generate

# Never fall back to ad-hoc signing: it changes the designated requirement on every

# build, which silently resets the notification grant.
[group('setup')]
verify-identity:
    #!/usr/bin/env zsh
    if ! security find-identity -p codesigning 2>/dev/null | grep -q "{{ identity }}"; then
        echo "error: signing identity {{ identity }} not found in the login keychain" >&2
        exit 1
    fi

[group('build')]
generate:
    xcodegen generate --quiet

[group('build')]
build config="Debug": verify-identity generate
    #!/usr/bin/env zsh
    set -o pipefail
    xcodebuild {{ xcflags }} -scheme Continuity -configuration {{ config }} build 2>&1 \
        | { command -v xcbeautify >/dev/null && xcbeautify --quiet || tail -5 }

[group('build')]
build-release: (build "Release")

[group('develop')]
run: build
    #!/usr/bin/env zsh
    set -euo pipefail
    pkill -x continuity 2>/dev/null || true
    while pgrep -x continuity >/dev/null; do sleep 0.2; done
    open "{{ built }}"

# Build, replace /Applications/continuity.app, launch it from there.
[group('deploy')]
install-app: build
    #!/usr/bin/env zsh
    set -euo pipefail
    pkill -x continuity 2>/dev/null || true
    # `open` fails with -600 if the old copy is still tearing down.
    while pgrep -x continuity >/dev/null; do sleep 0.2; done
    rm -rf "/Applications/continuity.app"
    # ditto, not cp: it keeps the bundle's metadata and signature intact.
    ditto "{{ built }}" "/Applications/continuity.app"
    open "/Applications/continuity.app"
    echo "→ Installed and launched /Applications/continuity.app"

[group('develop')]
xcode: generate
    open Continuity.xcodeproj

# Confirms the signature is the stable one, so the notification grant survives.
[group('develop')]
dr:
    codesign -d -r- "{{ built }}" 2>&1 | tail -1

[group('quality')]
test:
    #!/usr/bin/env zsh
    set -o pipefail
    xcodebuild {{ xcflags }} -scheme Continuity -configuration Debug test 2>&1 \
        | { command -v xcbeautify >/dev/null && xcbeautify --quiet || grep -E 'Test|error|passed|failed' }

[group('quality')]
lint:
    swiftlint lint --strict

[group('quality')]
lint-fix:
    swiftlint --fix && swiftlint lint --strict

[group('quality')]
just-fmt-check:
    just --fmt --check

[group('quality')]
loc-check:
    #!/usr/bin/env zsh
    setopt null_glob
    eval "$(python3 -c "
    import json, shlex
    c = json.load(open('.quality.json'))
    print(f'WARN={c[\"loc\"][\"warn\"]}')
    print(f'ERROR={c[\"loc\"][\"error\"]}')
    g = c['globs']
    print(f'GLOBS=({shlex.join(g)})')
    ")"
    err=0
    for pattern in $GLOBS; do
        for f in ${~pattern}; do
            lines=$(wc -l < "$f")
            if (( lines > ERROR )); then echo "error: $f ($lines lines, max $ERROR)"; err=1
            elif (( lines > WARN )); then echo "warn: $f ($lines lines, target ≤$WARN — don't trim, split the file!)"; fi
        done
    done
    exit $err

[group('quality')]
dir-check:
    #!/usr/bin/env zsh
    setopt null_glob
    eval "$(python3 -c "
    import json, shlex
    c = json.load(open('.quality.json'))
    print(f'MAX={c[\"dir\"][\"max_files\"]}')
    g = c['globs']
    print(f'GLOBS=({shlex.join(g)})')
    ")"
    err=0
    typeset -A counts
    for pattern in $GLOBS; do
        for f in ${~pattern}; do
            dir=${f:h}
            counts[$dir]=$(( ${counts[$dir]:-0} + 1 ))
        done
    done
    for dir count in ${(kv)counts}; do
        if (( count > MAX )); then
            echo "error: $dir ($count files, max $MAX)"
            err=1
        fi
    done
    exit $err

[group('quality')]
check:
    @echo '→ Justfile format...'
    just just-fmt-check
    @echo '→ File lengths...'
    just loc-check
    @echo '→ Directory sizes...'
    just dir-check
    @echo '→ Lint...'
    just lint
    @echo '→ Build...'
    just build
    @echo '→ Tests...'
    just test

# Everything below ships builds to other people. `just publish` is the whole chain;
# the recipes it depends on are listed separately because each is worth running alone
# when something in it fails.
# The version moves here and nowhere else: MARKETING_VERSION, the build number

# Sparkle orders updates by, and the vX.Y.Z tag, in one commit behind the gate.
[group('release')]
bump part="": check
    python3 tools/bump-version.py {{ part }}

# What `just bump` would decide, without deciding it.
[group('release')]
next part="":
    @python3 tools/bump-version.py {{ part }} --dry-run

[group('release')]
archive: generate
    #!/usr/bin/env zsh
    set -o pipefail
    rm -rf "{{ archive_path }}"
    xcodebuild {{ xcflags }} -scheme Continuity -configuration Release \
        -archivePath "{{ archive_path }}" archive 2>&1 \
        | { command -v xcbeautify >/dev/null && xcbeautify --quiet || tail -5 }

# Sparkle explicitly discourages --deep; the export step signs nested code correctly.
[group('release')]
export-app: archive
    #!/usr/bin/env zsh
    set -o pipefail
    # Written here rather than committed: release/ is gitignored, and the only
    # variable in it is the team id, which the identity above already pins.
    mkdir -p "$(dirname "{{ export_options }}")"
    rm -f "{{ export_options }}"
    plutil -create xml1 "{{ export_options }}"
    plutil -insert method -string developer-id "{{ export_options }}"
    plutil -insert teamID -string {{ team }} "{{ export_options }}"
    plutil -insert signingStyle -string manual "{{ export_options }}"
    plutil -insert signingCertificate -string 'Developer ID Application' "{{ export_options }}"
    rm -rf "{{ export_dir }}"
    xcodebuild -exportArchive -archivePath "{{ archive_path }}" \
        -exportOptionsPlist "{{ export_options }}" -exportPath "{{ export_dir }}"

[group('release')]
notarize: export-app
    #!/usr/bin/env zsh
    set -o pipefail
    ditto -c -k --keepParent "{{ export_dir }}/continuity.app" "{{ zip_path }}"
    xcrun notarytool submit "{{ zip_path }}" --keychain-profile {{ notary }} --wait
    xcrun stapler staple "{{ export_dir }}/continuity.app"
    xcrun stapler validate "{{ export_dir }}/continuity.app"
    # Zipped twice on purpose. The first zip is what goes to Apple, and the ticket
    # only exists once that has come back — so the app inside it is unstapled, and
    # that zip is also what Sparkle hands to the installer. An app that has to ask
    # Apple online to prove itself is one that fails behind a captive portal.
    rm -f "{{ zip_path }}"
    ditto -c -k --keepParent "{{ export_dir }}/continuity.app" "{{ zip_path }}"

# Writes the private key to the login keychain and prints the public one.

# BACK THE PRIVATE KEY UP. Lose it and every installed copy is unupdatable forever.
[group('release')]
sparkle-keys:
    #!/usr/bin/env zsh
    bin=$(find .build -name generate_keys -type f -perm -111 2>/dev/null | head -1)
    if [[ -z "$bin" ]]; then
        echo "error: generate_keys not built yet — run 'just build' first" >&2
        exit 1
    fi
    "$bin" -p

# Signs the notarized zip and rewrites the committed appcast.
#
# The archives live in their own directory rather than in `release/export`, which
# `export-app` wipes: generate_appcast carries the *previous* entries across from the
# appcast it finds next to the archives, and a wiped directory would silently publish
# a feed with only the newest version in it.

[group('release')]
appcast:
    #!/usr/bin/env zsh
    set -euo pipefail
    bin=$(find .build -name generate_appcast -type f -perm -111 2>/dev/null | head -1)
    if [[ -z "$bin" ]]; then
        echo "error: generate_appcast not built yet — run 'just build' first" >&2
        exit 1
    fi
    mkdir -p "{{ appcast_dir }}"
    cp "{{ zip_path }}" "{{ appcast_dir }}/"
    # Same basename as the archive: that is how generate_appcast finds the notes.
    if [[ -f "docs/RELEASE-{{ version }}.md" ]]; then
        cp "docs/RELEASE-{{ version }}.md" "{{ appcast_dir }}/continuity-{{ version }}.md"
    else
        echo "warn: no docs/RELEASE-{{ version }}.md — the update will show no notes" >&2
    fi
    # --embed-release-notes: without it the notes become a *link* derived from
    # SUFeedURL's directory, so Sparkle would fetch them from the repo root and show
    # an empty pane. --maximum-deltas 0: an advertised delta that 404s fails the
    # update outright. --maximum-versions 1: every zip lives on its own release, and
    # generate_appcast rewrites every item's enclosure with the prefix of the run
    # that touched it — one item cannot go stale, and Sparkle only offers the newest.
    "$bin" --download-url-prefix "{{ releases_url }}/download/v{{ version }}/" \
        --link "{{ repo_url }}" \
        --full-release-notes-url "{{ releases_url }}" \
        --embed-release-notes \
        --maximum-deltas 0 \
        --maximum-versions 1 \
        "{{ appcast_dir }}"
    cp "{{ appcast_dir }}/appcast.xml" appcast.xml
    echo "→ appcast.xml rewritten — commit and push it, it *is* the feed"

# Ship it: push the tag, publish the GitHub release, then the feed that points at it.
# The appcast is committed last on purpose. It is the only thing installed copies

# read, so it must never name a download that is not on the release yet.
[group('release')]
publish: notarize
    #!/usr/bin/env zsh
    set -euo pipefail
    tag="v{{ version }}"
    git rev-parse "$tag" >/dev/null 2>&1 \
        || { echo "error: no tag $tag — run 'just bump' first" >&2; exit 1; }
    notes="docs/RELEASE-{{ version }}.md"
    [[ -f "$notes" ]] || { echo "error: $notes is missing" >&2; exit 1; }
    git push --follow-tags
    gh release create "$tag" --title "continuity {{ version }}" --notes-file "$notes" \
        "{{ zip_path }}"
    just appcast
    git add appcast.xml
    git commit -m "release: appcast for {{ version }}"
    git push
    echo "→ continuity {{ version }} published; the feed now offers it"

[group('cleanup')]
clean:
    rm -rf .build Continuity.xcodeproj "{{ archive_path }}" "{{ export_dir }}"

# Open this project's CLAUDE.md tree in the project-atlas viewer, https://github.com/doublej/project-atlas (via the global `atlas` CLI)
[group('docs')]
claude-tree:
    atlas tree

[group('scaffold')]
update-scaffold *ARGS:
    #!/usr/bin/env zsh
    set -euo pipefail
    repo="${COOKIECUTTER_TEMPLATES:-}"
    if [[ -z "$repo" && -f .template-meta.json ]]; then
        repo=$(python3 -c "import json; print(json.load(open('.template-meta.json'))['template_source']['path'])" 2>/dev/null || true)
    fi
    if [[ -z "$repo" || ! -d "$repo" ]]; then
        echo "error: cookiecutter-templates repo not found — set \$COOKIECUTTER_TEMPLATES or fix template_source.path in .template-meta.json" >&2
        exit 1
    fi
    python3 "$repo/tools/update_scaffold.py" {{ ARGS }}
