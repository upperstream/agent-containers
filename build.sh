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

usage() {
	cat <<-'EOF'
	Usage: build.sh [options]

	Build the production and development "agents" container images from
	the repository Dockerfile and tag them based on the current git
	branch, commit, and working tree state.

	Options:
	  -h, -H, --help    Show this help and exit

	Environment:
	  DOCKER            Container engine to use (default: podman if
	                    available, otherwise docker)

	Examples:
	  build.sh          Build and tag the images
	  build.sh -h       Show this help
	EOF
}

# Parse options
for arg in "$@"; do
	case "$arg" in
		-h|-H|--help)
			usage
			exit 0
			;;
		*)
			echo "error: unknown option: $arg" >&2
			usage >&2
			exit 2
			;;
	esac
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

# Create the production image (build with the first tag, re-tag the rest)
# shellcheck disable=SC2086
set -- $prod_tags
first=$1
shift
$docker build --build-arg ENVIRONMENT=production --build-arg NANO_CLASSIC_KEYBINDINGS=yes -t "agents:$first" . || exit 1
built="agents:$first"
for t in "$@"; do
	$docker tag "agents:$first" "agents:$t" && built="$built
agents:$t"
done

# Create the development image
# shellcheck disable=SC2086
set -- $dev_tags
first=$1
shift
$docker build --build-arg ENVIRONMENT=development --build-arg NANO_CLASSIC_KEYBINDINGS=yes -t "agents:$first" . || exit 1
built="$built
agents:$first"
for t in "$@"; do
	$docker tag "agents:$first" "agents:$t" && built="$built
agents:$t"
done

# Report
echo "Successfully built:"
echo "$built"
