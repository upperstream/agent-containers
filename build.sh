#!/bin/sh

# Image tagging rule.
#
# For every build we decide a set of production tags and a set of development
# tags. In two cases the image is tagged twice -- the tip of master, and the
# tip of a non-master branch, when the current commit carries a git tag: the
# git-tag-derived tag is applied IN ADDITION TO the "latest"/branch-name tag.
#
#   case                                          production tags        development tags
#   master, working dir modified                  wip                    dev-wip
#   master, clean, tip, git tag T                 latest, T              dev, dev-T
#   master, clean, tip, no tag                    latest                 dev
#   master, clean, not at tip, git tag T          T                      dev-T
#   master, clean, not at tip, no tag             wip                    dev-wip
#   branch, working dir modified                  branch-wip             dev-branch-wip
#   branch, clean, tip, git tag T                 branch, branch-T       dev-branch, dev-branch-T
#   branch, clean, tip, no tag                    branch                 dev-branch
#   branch, clean, not at tip, git tag T          branch-T               dev-branch-T
#   branch, clean, not at tip, no tag             branch-wip             dev-branch-wip
#
# The same tag sets are applied to every image that is built.  Providers are
# given as command line arguments: a provider name is the directory name of
# its standalone build, except `openwiki` (directory openwiki-agent).
# `root` builds the root Dockerfile only (image name agents), and the
# default (no provider given) is `root`.  The -a/--all option builds the
# root Dockerfile plus all standalone providers.
#
# Pass `--test` as the only argument to run the built-in self-test.

usage() {
	cat <<-'EOF'
	Usage: build.sh [options] [PROVIDER...]

	Build and tag production and development container images based on the
	current git branch, commit, and working tree state.

	Providers:
	  (none)            Root Dockerfile only (image: agents)
	  root              Root Dockerfile (image: agents)
	  openwiki          Standalone OpenWiki (directory: openwiki-agent)
	  <directory name>  Standalone build for the named provider; the image
	                    name is the directory name

	Options:
	  -h, -H, --help        Show this help and exit
	  -k, --keep-going      Keep building even when a build fails
	  -a, --all             Build the root Dockerfile and all standalone
	                        providers
	  --test                Run the built-in self-test (no other arguments)

	Environment:
	  DOCKER            Container engine to use (default: podman if
	                    available, otherwise docker)

	Examples:
	  build.sh            Build and tag the root images
	  build.sh grok pi    Build and tag the standalone grok and pi images
	  build.sh -k -a      Build everything, continuing past failures
	  build.sh -h         Show this help
	  build.sh --test     Run the built-in self-test
	EOF
}

# Standalone providers: the provider name is the directory name, except
# openwiki which lives in the openwiki-agent directory
standalone_providers="aider antigravity claude cline codex copilot crush cursor droid gemini grok herdr hermes kilo kiro openclaw opencode openwiki pi"

# Parse options and provider arguments.  Sets keep_going and resolved.
parse_args() {
	keep_going=no
	build_all=no
	providers=
	for arg in "$@"; do
		case $arg in
			-h|-H|--help)
				usage
				exit 0
				;;
			-k|--keep-going)
				keep_going=yes
				;;
			-a|--all)
				build_all=yes
				;;
			-*)
				echo "error: unknown option: $arg" >&2
				usage >&2
				exit 2
				;;
			*)
				providers="$providers $arg"
				;;
		esac
	done

	# Resolve the provider list: -a builds the root Dockerfile and all
	# standalone providers, otherwise the given providers (defaulting to
	# root), deduplicated, order preserved
	if [ "$build_all" = yes ]; then
		providers="root $standalone_providers"
	else
		[ -n "$providers" ] || providers="root"
	fi
	resolved=
	for q in $providers; do
		case " root $standalone_providers " in
			*" $q "*) ;;
			*)
				echo "error: unknown provider: $q" >&2
				usage >&2
				exit 2
				;;
		esac
		case " $resolved " in
			*" $q "*) ;;
			*) resolved="$resolved $q" ;;
		esac
	done

	# Check that the standalone Dockerfiles exist
	for name in $resolved; do
		[ "$name" = root ] && continue
		case $name in
			openwiki) dir=openwiki-agent ;;
			*)        dir=$name ;;
		esac
		if [ ! -f "$dir/Dockerfile" ]; then
			echo "error: provider $name: $dir/Dockerfile not found" >&2
			exit 2
		fi
	done
}

# Determine the git state.  Sets branch, git_tag, modified, at_tip.
detect_git_state() {
	# Current branch; for detached HEAD fall back to the short commit hash
	branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
		echo "error: not a git repository" >&2
		exit 1
	}
	if [ "$branch" = "HEAD" ]; then
		branch=$(git rev-parse --short HEAD)
	fi

	# Git tag on current commit, if any (first one if several)
	git_tag=$(git tag --points-at HEAD 2>/dev/null | head -n 1)

	# Working directory modified, staged or not (modified files or
	# untracked files)
	modified=no
	if ! git diff-index --quiet HEAD -- 2>/dev/null; then
		modified=yes
	elif git ls-files --others --exclude-standard | grep -q .; then
		modified=yes
	fi

	# Branch tip: the tip of the remote-tracking branch (origin/<branch>),
	# falling back to the local branch tip when no remote ref exists
	head_commit=$(git rev-parse HEAD)
	if [ "$branch" = master ]; then
		tip_commit=$(git rev-parse --verify -q origin/master || echo "$head_commit")
	else
		tip_commit=$(git rev-parse --verify -q "origin/$branch" || git rev-parse --verify -q "$branch^{commit}" || echo "$head_commit")
	fi
	at_tip=no
	if [ "$head_commit" = "$tip_commit" ]; then
		at_tip=yes
	fi
}

# Select the production / development tag sets (space-separated) from the
# git state determined by detect_git_state.  Sets prod_tags, dev_tags.
select_tag_sets() {
	if [ "$modified" = yes ]; then
		if [ "$branch" = master ]; then
			prod_tags="wip"
			dev_tags="dev-wip"
		else
			prod_tags="$branch-wip"
			dev_tags="dev-$branch-wip"
		fi
	elif [ -n "$git_tag" ]; then
		if [ "$branch" = master ]; then
			if [ "$at_tip" = yes ]; then
				prod_tags="latest $git_tag"
				dev_tags="dev dev-$git_tag"
			else
				prod_tags="$git_tag"
				dev_tags="dev-$git_tag"
			fi
		else
			if [ "$at_tip" = yes ]; then
				prod_tags="$branch $branch-$git_tag"
				dev_tags="dev-$branch dev-$branch-$git_tag"
			else
				prod_tags="$branch-$git_tag"
				dev_tags="dev-$branch-$git_tag"
			fi
		fi
	else
		if [ "$branch" = master ]; then
			if [ "$at_tip" = yes ]; then
				prod_tags="latest"
				dev_tags="dev"
			else
				prod_tags="wip"
				dev_tags="dev-wip"
			fi
		else
			if [ "$at_tip" = yes ]; then
				prod_tags="$branch"
				dev_tags="dev-$branch"
			else
				prod_tags="$branch-wip"
				dev_tags="dev-$branch-wip"
			fi
		fi
	fi
}

# Determine podman (preferred) or docker; `DOCKER` overrides automatic
# selection.  Sets docker.
select_engine() {
	docker="${DOCKER:-$(command -v podman 2>/dev/null)}"
	docker="${docker:-$(command -v docker 2>/dev/null)}"
	if [ -z "$docker" ]; then
		echo "error: neither podman nor docker found" >&2
		exit 1
	fi
}

# Build one image for a provider and environment, then apply the remaining
# tags.  $1 = provider name, $2 = environment, $3 = space-separated tags
build_image() {
	name=$1
	environment=$2
	# shellcheck disable=SC2086
	set -- $3
	first=$1
	shift
	if [ "$name" = root ]; then
		image=agents
		context=.
	else
		case $name in
			openwiki) context=openwiki-agent ;;
			*)        context=$name ;;
		esac
		image=$name
	fi
	if ! $docker build --build-arg ENVIRONMENT="$environment" \
			--build-arg NANO_CLASSIC_KEYBINDINGS=yes \
			-t "$image:$first" "$context"; then
		return 1
	fi
	tags="$image:$first"
	for t in "$@"; do
		if ! $docker tag "$image:$first" "$image:$t"; then
			return 1
		fi
		tags="$tags
$image:$t"
	done
	built="$built
$tags"
	return 0
}

# Entry point for a normal build: parse arguments, determine the git state
# and tag sets, select the engine, build every image, report the result.
main() {
	parse_args "$@"
	detect_git_state
	select_tag_sets
	select_engine

	# Images built so far, one per line (leading newline stripped when
	# printing)
	built=
	failed=
	fail=0

	# Build the production and development image of every resolved
	# provider, stopping at the first failure unless -k was given
	stop=no
	for environment in production development; do
		if [ "$environment" = production ]; then
			tagset=$prod_tags
		else
			tagset=$dev_tags
		fi
		for name in $resolved; do
			if ! build_image "$name" "$environment" "$tagset"; then
				failed="$failed
$name ($environment)"
				fail=1
				[ "$keep_going" = no ] && stop=yes
			fi
			[ "$stop" = yes ] && break
		done
		[ "$stop" = yes ] && break
	done

	# Report
	if [ -n "$built" ]; then
		echo "Successfully built:"
		echo "${built#
}"
	fi
	if [ -n "$failed" ]; then
		echo "Failed to build:" >&2
		echo "${failed#
}" >&2
	fi
	if [ "$fail" = 1 ]; then
		exit 1
	fi
}

# ----------------------------------------------------------------------
# Self-test (run with: build.sh --test)
#
# The test drives main() in-process: each case runs in a subshell from a
# scratch git repository with a stub container engine (selected via
# DOCKER) and asserts on the stub's invocation log and on the output of
# the run.  build.sh is never invoked as a subprocess from the test.
# ----------------------------------------------------------------------

t_pass=0
t_fail=0

t_ok() {
	t_pass=$((t_pass + 1))
	echo "ok   [$1]"
}

t_bad() {
	t_fail=$((t_fail + 1))
	echo "FAIL [$1]: $2"
}

# t_reset: clear the stub's state files and the output capture
t_reset() {
	rm -f "$tdir/count" "$tdir/fail_at"
	: > "$t_log"
	: > "$t_out"
}

# t_run <want_rc> <desc> [args...]: run main in a subshell with the stub
# engine and compare the exit code
t_run() {
	want_rc=$1
	desc=$2
	shift 2
	t_reset
	# shellcheck disable=SC2030,SC2164
	( cd "$t_scratch"
	  export BTEST_DIR="$tdir" DOCKER="$tdir/bin/docker"
	  main "$@"
	) > "$t_out" 2>&1
	got_rc=$?
	if [ "$got_rc" != "$want_rc" ]; then
		t_bad "$desc" "rc=$got_rc want=$want_rc"
		sed 's/^/    /' "$t_out"
		return 1
	fi
	t_ok "$desc"
	return 0
}

# t_run_fail <want_rc> <desc> <fail_n> [args...]: like t_run, but the
# stub fails its Nth build invocation
t_run_fail() {
	want_rc=$1
	desc=$2
	fail_n=$3
	shift 3
	t_reset
	echo "$fail_n" > "$tdir/fail_at"
	# shellcheck disable=SC2030,SC2031,SC2164
	( cd "$t_scratch"
	  export BTEST_DIR="$tdir" DOCKER="$tdir/bin/docker"
	  main "$@"
	) > "$t_out" 2>&1
	got_rc=$?
	if [ "$got_rc" != "$want_rc" ]; then
		t_bad "$desc" "rc=$got_rc want=$want_rc"
		sed 's/^/    /' "$t_out"
		return 1
	fi
	t_ok "$desc"
	return 0
}

# t_logline <desc> <line> <expected>: check one line of the stub's log
t_logline() {
	got=$(sed -n "${2}p" "$t_log")
	if [ "$got" != "$3" ]; then
		t_bad "$1" "log line $2: '$got' want '$3'"
		return 1
	fi
	t_pass=$((t_pass + 1))
}

# t_out_has <desc> <substring>: check the captured output of the run
t_out_has() {
	if grep -qF -- "$2" "$t_out"; then
		t_pass=$((t_pass + 1))
	else
		t_bad "$1" "output missing: $2"
	fi
}

t_loglines() {
	wc -l < "$t_log" | tr -d ' '
}

# t_expect_lines <desc> <count>: check the number of lines in the stub's
# log
t_expect_lines() {
	got=$(t_loglines)
	if [ "$got" != "$2" ]; then
		t_bad "$1" "log lines: $got want $2"
	else
		t_pass=$((t_pass + 1))
	fi
}

# t_mkdirs: scratch repo layout (root Dockerfile and one directory per
# standalone provider, each with a minimal Dockerfile)
t_mkdirs() {
	rm -rf "$t_scratch"
	mkdir -p "$t_scratch"
	echo "FROM scratch" > "$t_scratch/Dockerfile"
	for d in $standalone_providers; do
		case $d in
			openwiki) dir="$t_scratch/openwiki-agent" ;;
			*)        dir="$t_scratch/$d" ;;
		esac
		mkdir -p "$dir"
		echo "FROM scratch" > "$dir/Dockerfile"
	done
}

t_git() {
	git -C "$t_scratch" -c user.email=test@test -c user.name=test "$@"
}

# t_repo_init: fresh scratch git repo on master with one clean commit
t_repo_init() {
	t_mkdirs
	rm -rf "$t_remote"
	git init -q --bare "$t_remote"
	git -C "$t_scratch" init -q -b master
	t_git add -A
	t_git commit -qm init
}

# t_dirty: make the working tree modified (untracked file)
t_dirty() {
	touch "$t_scratch/untracked"
}

t_branch() {
	t_git checkout -q -b "$1"
}

t_tag() {
	git -C "$t_scratch" tag "$1"
}

# t_behind_remote <branch>: make origin/<branch> one commit ahead of the
# local branch (HEAD is clean but not at the tip)
t_behind_remote() {
	git -C "$t_scratch" remote add origin "$t_remote"
	git -C "$t_scratch" push -q origin "$1"
	t_git commit -qm advance --allow-empty
	git -C "$t_scratch" push -q origin "$1"
	git -C "$t_scratch" reset -q --hard HEAD~1
}

run_tests() {
	tdir=$(mktemp -d) || {
		echo "error: mktemp -d failed" >&2
		return 1
	}
	t_scratch="$tdir/repo"
	t_remote="$tdir/remote.git"
	t_log="$tdir/log"
	t_out="$tdir/out"
	trap 'rm -rf "$tdir"' EXIT
	mkdir -p "$tdir/bin"

	# Stub container engine: logs every invocation to $BTEST_DIR/log and
	# fails the Nth build when $BTEST_DIR/fail_at contains N
	cat > "$tdir/bin/docker" <<'EOF'
#!/bin/sh
dir=${BTEST_DIR:-.}
cmd=$1
shift
case $cmd in
build)
	n=$(cat "$dir/count" 2>/dev/null || echo 0)
	n=$((n + 1))
	echo "$n" > "$dir/count"
	tag=
	prev=
	for a in "$@"; do
		[ "$prev" = "-t" ] && tag=$a
		prev=$a
	done
	ctx=
	for a in "$@"; do
		ctx=$a
	done
	echo "build $n ctx=$ctx tag=$tag" >> "$dir/log"
	fail_at=$(cat "$dir/fail_at" 2>/dev/null)
	if [ -n "$fail_at" ] && [ "$n" = "$fail_at" ]; then
		echo "stub: simulated failure on build #$n" >&2
		exit 1
	fi
	;;
tag)
	echo "tag src=$1 dst=$2" >> "$dir/log"
	;;
*)
	echo "stub: unexpected command: $cmd" >&2
	exit 1
	;;
esac
exit 0
EOF
	chmod +x "$tdir/bin/docker"

	echo "Self-test for build.sh"
	echo

	# Tag rule cases: main is run with root and grok; the stub log shows
	# build lines (and tag lines for double-tag cases)
	t_repo_init
	t_dirty
	t_run 0 "R1 master, modified" root grok
	t_logline R1 1 "build 1 ctx=. tag=agents:wip"
	t_logline R1 2 "build 2 ctx=grok tag=grok:wip"
	t_logline R1 3 "build 3 ctx=. tag=agents:dev-wip"
	t_logline R1 4 "build 4 ctx=grok tag=grok:dev-wip"
	t_expect_lines R1 4

	t_repo_init
	t_tag v1
	t_run 0 "R2 master, clean, tip, tagged" root grok
	t_logline R2 1 "build 1 ctx=. tag=agents:latest"
	t_logline R2 2 "tag src=agents:latest dst=agents:v1"
	t_logline R2 5 "build 3 ctx=. tag=agents:dev"
	t_logline R2 6 "tag src=agents:dev dst=agents:dev-v1"
	t_expect_lines R2 8

	t_repo_init
	t_run 0 "R3 master, clean, tip, no tag" root grok
	t_logline R3 1 "build 1 ctx=. tag=agents:latest"
	t_logline R3 2 "build 2 ctx=grok tag=grok:latest"
	t_logline R3 3 "build 3 ctx=. tag=agents:dev"
	t_logline R3 4 "build 4 ctx=grok tag=grok:dev"
	t_expect_lines R3 4

	t_repo_init
	t_behind_remote master
	t_tag v1
	t_run 0 "R4 master, clean, not at tip, tagged" root grok
	t_logline R4 1 "build 1 ctx=. tag=agents:v1"
	t_logline R4 2 "build 2 ctx=grok tag=grok:v1"
	t_logline R4 3 "build 3 ctx=. tag=agents:dev-v1"
	t_logline R4 4 "build 4 ctx=grok tag=grok:dev-v1"
	t_expect_lines R4 4

	t_repo_init
	t_behind_remote master
	t_run 0 "R5 master, clean, not at tip, no tag" root grok
	t_logline R5 1 "build 1 ctx=. tag=agents:wip"
	t_logline R5 2 "build 2 ctx=grok tag=grok:wip"
	t_logline R5 3 "build 3 ctx=. tag=agents:dev-wip"
	t_logline R5 4 "build 4 ctx=grok tag=grok:dev-wip"
	t_expect_lines R5 4

	t_repo_init
	t_branch feature
	t_dirty
	t_run 0 "R6 branch, modified" root grok
	t_logline R6 1 "build 1 ctx=. tag=agents:feature-wip"
	t_logline R6 2 "build 2 ctx=grok tag=grok:feature-wip"
	t_logline R6 3 "build 3 ctx=. tag=agents:dev-feature-wip"
	t_logline R6 4 "build 4 ctx=grok tag=grok:dev-feature-wip"
	t_expect_lines R6 4

	t_repo_init
	t_branch feature
	t_tag v1
	t_run 0 "R7 branch, clean, tip, tagged" root grok
	t_logline R7 1 "build 1 ctx=. tag=agents:feature"
	t_logline R7 2 "tag src=agents:feature dst=agents:feature-v1"
	t_logline R7 5 "build 3 ctx=. tag=agents:dev-feature"
	t_logline R7 6 "tag src=agents:dev-feature dst=agents:dev-feature-v1"
	t_expect_lines R7 8

	t_repo_init
	t_branch feature
	t_run 0 "R8 branch, clean, tip, no tag" root grok
	t_logline R8 1 "build 1 ctx=. tag=agents:feature"
	t_logline R8 2 "build 2 ctx=grok tag=grok:feature"
	t_logline R8 3 "build 3 ctx=. tag=agents:dev-feature"
	t_logline R8 4 "build 4 ctx=grok tag=grok:dev-feature"
	t_expect_lines R8 4

	t_repo_init
	t_branch feature
	t_behind_remote feature
	t_tag v1
	t_run 0 "R9 branch, clean, not at tip, tagged" root grok
	t_logline R9 1 "build 1 ctx=. tag=agents:feature-v1"
	t_logline R9 2 "build 2 ctx=grok tag=grok:feature-v1"
	t_logline R9 3 "build 3 ctx=. tag=agents:dev-feature-v1"
	t_logline R9 4 "build 4 ctx=grok tag=grok:dev-feature-v1"
	t_expect_lines R9 4

	t_repo_init
	t_branch feature
	t_behind_remote feature
	t_run 0 "R10 branch, clean, not at tip, no tag" root grok
	t_logline R10 1 "build 1 ctx=. tag=agents:feature-wip"
	t_logline R10 2 "build 2 ctx=grok tag=grok:feature-wip"
	t_logline R10 3 "build 3 ctx=. tag=agents:dev-feature-wip"
	t_logline R10 4 "build 4 ctx=grok tag=grok:dev-feature-wip"
	t_expect_lines R10 4

	# Provider and option cases (scratch repo: master, clean, at tip)
	t_repo_init
	t_run 0 "P1 no providers -> root only"
	t_logline P1 1 "build 1 ctx=. tag=agents:latest"
	t_logline P1 2 "build 2 ctx=. tag=agents:dev"
	t_expect_lines P1 2

	t_repo_init
	t_run 0 "P2 grok pi" grok pi
	t_logline P2 1 "build 1 ctx=grok tag=grok:latest"
	t_logline P2 2 "build 2 ctx=pi tag=pi:latest"
	t_logline P2 3 "build 3 ctx=grok tag=grok:dev"
	t_logline P2 4 "build 4 ctx=pi tag=pi:dev"
	t_expect_lines P2 4

	t_repo_init
	t_run 0 "P3 openwiki" openwiki
	t_logline P3 1 "build 1 ctx=openwiki-agent tag=openwiki:latest"
	t_expect_lines P3 2

	t_repo_init
	t_run 0 "P4 dedup" root root grok
	t_logline P4 1 "build 1 ctx=. tag=agents:latest"
	t_logline P4 2 "build 2 ctx=grok tag=grok:latest"
	t_logline P4 3 "build 3 ctx=. tag=agents:dev"
	t_logline P4 4 "build 4 ctx=grok tag=grok:dev"
	t_expect_lines P4 4

	t_repo_init
	t_run 0 "P5 -a flag" -a
	t_expect_lines P5 40
	t_logline P5 1 "build 1 ctx=. tag=agents:latest"
	t_logline P5 2 "build 2 ctx=aider tag=aider:latest"
	t_logline P5 21 "build 21 ctx=. tag=agents:dev"
	t_logline P5 40 "build 40 ctx=pi tag=pi:dev"
	t_out_has P5 "openwiki:dev"

	t_repo_init
	t_run_fail 1 "P6 keep-going past failure" 5 -k -a
	t_expect_lines P6 40
	t_out_has P6 "Failed to build:"
	t_out_has P6 "cline (production)"
	t_out_has P6 "Successfully built:"

	t_repo_init
	t_run_fail 1 "P7 stop at first failure" 5 -a
	t_expect_lines P7 5
	t_out_has P7 "Failed to build:"
	t_out_has P7 "cline (production)"

	t_repo_init
	t_run_fail 1 "P8 keep-going long form" 5 --keep-going --all
	t_expect_lines P8 40
	t_out_has P8 "Failed to build:"

	t_repo_init
	t_run 2 "P9 unknown provider" bogus
	t_out_has P9 "unknown provider: bogus"

	t_repo_init
	t_run 2 "P10 all is not a provider" all
	t_out_has P10 "unknown provider: all"

	t_repo_init
	t_run 2 "P11 unknown option" -x
	t_out_has P11 "unknown option: -x"

	t_repo_init
	t_run 0 "P12 help" -h
	t_out_has P12 "Usage: build.sh"
	t_out_has P12 "-k"
	t_out_has P12 "-a, --all"

	# P13: neither podman nor docker on PATH (and DOCKER unset)
	t_repo_init
	t_reset
	mkdir -p "$tdir/nobin"
	for c in git grep head; do
		ln -sf "$(command -v "$c")" "$tdir/nobin/$c"
	done
	# shellcheck disable=SC2031,SC2164
	( cd "$t_scratch"
	  export PATH="$tdir/nobin" DOCKER=
	  main root
	) > "$t_out" 2>&1
	got_rc=$?
	if [ "$got_rc" = 1 ]; then
		t_ok "P13 no engine"
	else
		t_bad "P13 no engine" "rc=$got_rc want 1"
	fi
	t_out_has P13 "neither podman nor docker found"

	echo
	echo "PASS=$t_pass FAIL=$t_fail"
	[ "$t_fail" = 0 ]
}

# Dispatch: --test (the only argument) runs the self-test, otherwise a
# normal build
if [ "$#" -ge 1 ] && [ "$1" = "--test" ]; then
	if [ "$#" -ne 1 ]; then
		echo "error: --test takes no other arguments" >&2
		exit 2
	fi
	run_tests
	exit $?
fi

main "$@"
