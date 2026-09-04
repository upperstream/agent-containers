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
# `root` builds the root Dockerfile only (image name agents), `all` builds
# the root Dockerfile plus all standalone providers, and the default (no
# provider given) is `root`.

usage() {
	cat <<-'EOF'
	Usage: build.sh [options] [PROVIDER...]

	Build and tag production and development container images based on the
	current git branch, commit, and working tree state.

	Providers:
	  (none)            Root Dockerfile only (image: agents)
	  root              Root Dockerfile (image: agents)
	  openwiki          Standalone OpenWiki (directory: openwiki-agent)
	  all               Root Dockerfile and all standalone providers
	  <directory name>  Standalone build for the named provider; the image
	                    name is the directory name

	Options:
	  -h, -H, --help        Show this help and exit
	  -k, --keep-going      Keep building even when a build fails

	Environment:
	  DOCKER            Container engine to use (default: podman if
	                    available, otherwise docker)

	Examples:
	  build.sh            Build and tag the root images
	  build.sh grok pi    Build and tag the standalone grok and pi images
	  build.sh -k all     Build everything, continuing past failures
	  build.sh -h         Show this help
	EOF
}

# Standalone providers: the provider name is the directory name, except
# openwiki which lives in the openwiki-agent directory
standalone_providers="aider antigravity claude cline codex copilot crush cursor droid gemini grok herdr hermes kilo kiro openclaw opencode openwiki pi"

# Parse options and providers
keep_going=no
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

# Resolve the provider list (default to root, deduplicate, keep order)
[ -n "$providers" ] || providers="root"
resolved=
for p in $providers; do
	case $p in
		all)
			p="root $standalone_providers"
			;;
	esac
	for q in $p; do
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

# Working directory modified, staged or not (modified files or untracked files)
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

# Determine production / development tag sets (space-separated)
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

# Determine podman (preferred) or docker; `DOCKER` overrides automatic selection
docker="${DOCKER:-$(command -v podman 2>/dev/null)}"
docker="${docker:-$(command -v docker 2>/dev/null)}"
if [ -z "$docker" ]; then
	echo "error: neither podman nor docker found" >&2
	exit 1
fi

# Images built so far, one per line (leading newline stripped when printing)
built=
failed=
fail=0

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

# Build the production and development image of every resolved provider,
# stopping at the first failure unless -k was given
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
