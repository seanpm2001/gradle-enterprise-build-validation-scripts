#!/usr/bin/env bash
#
# Runs Experiment 01 -  Optimize for incremental building
#

# ARG_OPTIONAL_SINGLE([git-url],[u],[Git repository URL for the repository containing the project for the experiment])
# ARG_OPTIONAL_SINGLE([branch],[b],[branch to checkout when cloning the repo before running the experiment])
# ARG_OPTIONAL_SINGLE([task],[t],[Gradle task to invoke when running builds as part of the experiment])
# ARG_OPTIONAL_BOOLEAN([wizard],[],[controls whether or not the wizard is run],[off])
# ARG_HELP([Experiment to validate that a build is fully using Gradle's incremental build feature.])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.10.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


begins_with_short_option()
{
	local first_option all_short_options='ubth'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_git_url=
_arg_branch=
_arg_task=
_arg_wizard="off"


print_help()
{
	printf '%s\n' "Experiment to validate that a build is fully using Gradle's incremental build feature."
	printf 'Usage: %s [-u|--git-url <arg>] [-b|--branch <arg>] [-t|--task <arg>] [--(no-)wizard] [-h|--help]\n' "$0"
	printf '\t%s\n' "-u, --git-url: Git repository URL for the repository containing the project for the experiment (no default)"
	printf '\t%s\n' "-b, --branch: branch to checkout when cloning the repo before running the experiment (no default)"
	printf '\t%s\n' "-t, --task: Gradle task to invoke when running builds as part of the experiment (no default)"
	printf '\t%s\n' "--wizard, --no-wizard: controls whether or not the wizard is run (off by default)"
	printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-u|--git-url)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_git_url="$2"
				shift
				;;
			--git-url=*)
				_arg_git_url="${_key##--git-url=}"
				;;
			-u*)
				_arg_git_url="${_key##-u}"
				;;
			-b|--branch)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_branch="$2"
				shift
				;;
			--branch=*)
				_arg_branch="${_key##--branch=}"
				;;
			-b*)
				_arg_branch="${_key##-b}"
				;;
			-t|--task)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_task="$2"
				shift
				;;
			--task=*)
				_arg_task="${_key##--task=}"
				;;
			-t*)
				_arg_task="${_key##-t}"
				;;
			--no-wizard|--wizard)
				_arg_wizard="on"
				test "${1:0:5}" = "--no-" && _arg_wizard="off"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
				;;
		esac
		shift
	done
}

parse_commandline "$@"
# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash

set -e
script_name=$(basename "$0")
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
experiment_dir="${script_dir}/data/${script_name%.*}"
run_id=$(uuidgen)

main() {
 print_introduction
 print_scan_tags
 collect_project_details
 collect_gradle_task
 make_experiment_dir
 clone_project
 execute_first_build
 execute_second_build
 open_build_scan_comparison
 print_wrap_up
 print_summary
}

print_scan_tags() {
  wizard "Below is the ID for this particular run of this experiment. Every time you run this script, \
we'll generate a new unique ID. This ID is added as a tag on all of the build scans, which \
makes it easy to find the build scans for each run of the experiment. We will also add an \
'exp1' tag to every build scan so that you can easily find all of the build scans for all \
runs of this experiment."

  local fmt="%-20s%-10s"

  info
  infof "$fmt" "Experiment Tag:" "exp1"
  infof "$fmt" "Experiment Run ID:" "${run_id}"
  info
}

collect_project_details() {
  wizard "We are going to create a fresh checkout of your project. That way, the experiment will be \
infleunced by as few outside factors as possible)."

  echo

  if [ -n "${_arg_git_url}" ]; then
     project_url=$_arg_git_url
  else
    read -r -p "What is the project's GitHub URL? " project_url
  fi

  if [ -n "${_arg_branch}" ]; then
     project_branch=$_arg_branch
  else
     read -r -p "What branch should we checkout (press enter to use the project's default branch)? " project_branch
  fi
  echo

  project_name=$(basename -s .git "${project_url}")
}

collect_gradle_task() {
  if [ -z "$_arg_task" ]; then
    wizard "We need a build task (or tasks) to run on each build of the experiment. If this is the first \
time you are running the experiment, then you may want to run a task that doesn't take very long to \
complete. You can run more complete (and longer) builds after you become more comfortable with running \
the experiment."

    echo
    read -r -p "What Gradle task do you want to run? (assemble) " task
    echo

    if [[ "${task}" == "" ]]; then
      task=assemble
    fi
  else
    task=$_arg_task
  fi
}

make_experiment_dir() {
  mkdir -p "${experiment_dir}"
  wizard "I just created ${YELLOW}${experiment_dir}${BLUE} where we will do the work for this experiment."
  wizard
}

clone_project() {
   info "Cloning ${project_name}"
   info

   local clone_dir="${experiment_dir}/${project_name}"

   local branch=""
   if [ -n "${project_branch}" ]; then
      branch="--branch ${project_branch}"
   fi

   rm -rf "${clone_dir}"
   # shellcheck disable=SC2086  # we want $branch to expand into multiple arguments
   git clone --depth=1 ${branch} "${project_url}" "${clone_dir}"
   cd "${clone_dir}"
   info
}

execute_first_build() {
  info "Running first build (invoking clean)."
  wizard 
  wizard "OK! We are ready to run our first build!"
  wizard
  wizard "For this run, we'll execute 'clean ${task}'. We will also add a few more flags to \
make sure build caching is disabled (since we are just focused on icremental building \
for now), and to add the build scan tags we talked about before. I will use a Gradle \
init script to capture the build scan information. That's for me though, you can totally \
ignore that part."
  wizard
  wizard "Effectively, this is what we are going to run (the actual command is a bit more complex):"

  info 
  info "./gradlew --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${run_id} clean ${task}"

  wizard_pause "Press enter to run the first build."

  invoke_gradle --no-build-cache clean "${task}"
}

execute_second_build() {
  info "Running second build (without invoking clean)."
  wizard
  wizard "Now we are going to run the build again, but this time we will invoke it without \
'clean'. This will let us see how well the build takes advantage of Gradle's incremental build."

  info 
  info "./gradlew --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${run_id} ${task}"

  wizard_pause "Press enter to run the second build."

  invoke_gradle --no-build-cache "${task}"
}

read_scan_info() {
  base_url=()
  scan_url=()
  scan_id=()
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  while IFS=, read -r field_1 field_2 field_3; do
     base_url+=("$field_1")
     scan_id+=("$field_2")
     scan_url+=("$field_3")
  done < scans.csv
}

open_build_scan_comparison() {
  wizard "It is time to compare the build scans from both builds. \
If you are unfamiliar with build scan comparisions then you might want to look this over with \
a Gradle Solutions engineer (who can help you to interpret the data)."
  wizard
  wizard "After you are done looking at the scan comparison, come back here and I will share with \
you some final thoughts."
  wizard

  read -r -p "Press enter to to open the build scan comparision in your default browser."
  read_scan_info

  local OS
  OS=$(uname)
  case $OS in
    'Darwin') browse=open ;;
    'WindowsNT') browse=start ;;
    *) browse=xdg-open ;;
  esac
  $browse "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs"
}

print_summary() {
 read_scan_info

 local fmt="%-20s%-10s"

 local branch
 branch=$(git branch)
 if [ -n "$_arg_branch" ]; then
   branch=${_arg_branch}
 fi

 info "${GREEN}DONE!${RESTORE}"
 info
 info "SUMMARY"
 info "----------------------------"
 infof "$fmt" "Project:" "${project_name}"
 infof "$fmt" "Branch:" "${branch}"
 infof "$fmt" "Gradle Task(s):" "${task}"
 infof "$fmt" "Experiment Dir:" "${experiment_dir}"
 infof "$fmt" "Experiment Tag:" "exp1"
 infof "$fmt" "Experiment Run ID:" "${run_id}"
 infof "$fmt" "First Build Scan:" "${scan_url[0]}"
 infof "$fmt" "Second Build Scan:" "${scan_url[1]}"
 infof "$fmt" "Scan Comparision:" "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs"
 info
}

invoke_gradle() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local script_dir_rel
  script_dir_rel=$(realpath --relative-to="$( pwd )" "${script_dir}")
  ./gradlew --init-script "${script_dir_rel}/capture-build-scan-info.gradle" -Dscan.tag.exp1 -Dscan.tag."${run_id}" "$@"
}

info() {
  printf "${YELLOW}${BOLD}%s${RESTORE}\n" "$1"
}

infof() {
  local format_string="$1"
  shift
  printf "${YELLOW}${BOLD}${format_string}${RESTORE}\n" "$@"
}

wizard() {
  if [ "$_arg_wizard" == "on" ]; then
    printf "${BLUE}${BOLD}${1}${RESTORE}\n" | fmt -w 80
  fi
}

wizard_pause() {
  if [ "$_arg_wizard" == "on" ]; then
    echo "${YELLOW}"
    read -r -p "$1"
    echo "${RESTORE}"
  fi
}

print_introduction() {
  if [ "$_arg_wizard" == "on" ]; then
    cat <<EOF
${CYAN}
                              ;x0K0d,
                             kXOxx0XXO,
               ....                '0XXc
        .;lx0XXXXXXXKOxl;.          oXXK
       xXXXXXXXXXXXXXXXXXX0d:.     ,KXX0
      .,KXXXXXXXXXXXXXXXXXO0XXKOxkKXXXX:
    lKX:'0XXXXXKo,dXXXXXXO,,XXXXXXXXXK;       Gradle Enterprise Trial
  ,0XXXXo.oOkl;;oKXXXXXXXXXXXXXXXXXKo.
 :XXXXXXXKdllxKXXXXXXXXXXXXXXXXXX0c.
'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'
xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXc           Experiment 1:
KXXXXXXXXXXXXXXXXXXXXXXXXXXXXl            Optimize for Incremental Build
XXXXXXklclkXXXXXXXklclxKXXXXK
OXXXk.     .OXXX0'     .xXXXx
oKKK'       ,KKK:       .KKKo
${RESTORE}${BLUE}${BOLD}

Wecome! This is the first of several experiments that are part of your Gradle
Enterprise Trial. Each experiment will help you to make concrete improvements
to your existing build. The experiments will also help you to build the data
necessary to recommend Gradle Enerprise to your organization.

This script (and the other experiment scripts) will run some of the experiment
steps for you, but we'll walk you through each step so that you know exactly
what we are doing, and why.

In this first experiment, we will be optimizing your existing build so that all
tasks participate in Gradle's incremental build feature. Gradle will only
execute tasks if their inputs have changed since the last time you ran them.
This let's Gradle avoid running tasks unecessarily (after all, why run a task
again if it's already completed it's work?).

For this experiment, we will run a clean build, and then we will run the same
build again without making any changes (but without invoking clean).
Afterwards, we'll look at the build scans to find tasks that were executed the
second time. In a fully optimized build, no tasks should run when no changes
have been made.

The Gradle Solutions engineer will then work with you to figure out why some
(if any) tasks ran on the second build, and how to optimize them so that all
tasks participate in Gradle's incremental building feature.

----------------------------------------------------------------------------${RESTORE}
EOF
    wizard_pause "Press enter when you're ready to get started."
  fi
}

print_wrap_up() {
  wizard
  wizard "Did you find any tasks to optimize? If so, great! You are one step \
closer to a faster build and a more productive team."
  wizard
  wizard "If you did find something to optimize, then you will want to run this \
expirment again after you have implemented the optimizations (to validate the \
optimizations were effective.)"
  wizard
  wizard "You will not have to go through this wizard again (that would be annoying). \
Instead, as long as you do not delete the experiment directory (${experiment_dir}), \
then the wizard will be skipped (the experiment will run without interruption). If for some \
reason the experiment directory does get deleted, then you can skip the wizard \
by running the script with the --no-wizard flag:"

  wizard "${YELLOW}${script_name} --no-wizard --task ${task}"

  wizard "Cheers!"
}

# Color and text escape sequences
RESTORE=$(echo -en '\033[0m')
RED=$(echo -en '\033[00;31m')
GREEN=$(echo -en '\033[00;32m')
YELLOW=$(echo -en '\033[00;33m')
BLUE=$(echo -en '\033[00;34m')
MAGENTA=$(echo -en '\033[00;35m')
PURPLE=$(echo -en '\033[00;35m')
CYAN=$(echo -en '\033[00;36m')
LIGHTGRAY=$(echo -en '\033[00;37m')
LRED=$(echo -en '\033[01;31m')
LGREEN=$(echo -en '\033[01;32m')
LYELLOW=$(echo -en '\033[01;33m')
LBLUE=$(echo -en '\033[01;34m')
LMAGENTA=$(echo -en '\033[01;35m')
LPURPLE=$(echo -en '\033[01;35m')
LCYAN=$(echo -en '\033[01;36m')
WHITE=$(echo -en '\033[01;37m')

BOLD=$(echo -en '\033[1m')
DIM=$(echo -en '\033[2m')
UNDERLINE=$(echo -en '\033[4m')


main

# ] <-- needed because of Argbash

