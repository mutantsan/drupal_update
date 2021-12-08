#!/usr/bin/env bash

# CONSTANTS
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "                                                                                                       ";
echo "██████╗ ██████╗ ██╗   ██╗██████╗  █████╗ ██╗         ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗";
echo "██╔══██╗██╔══██╗██║   ██║██╔══██╗██╔══██╗██║         ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝";
echo "██║  ██║██████╔╝██║   ██║██████╔╝███████║██║         ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  ";
echo "██║  ██║██╔══██╗██║   ██║██╔═══╝ ██╔══██║██║         ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  ";
echo "██████╔╝██║  ██║╚██████╔╝██║     ██║  ██║███████╗    ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗";
echo "╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝";
echo "                                                                                                       ";

branch_name=$1;
if [ -z $branch_name ]; then
    echo -e "${RED}Please, provide a feature branch name"
    exit 1;
fi

module_regex="${2:-drupal/*}"
composer="${COMPOSER_BIN:=$(which composer)}"
php="${PHP_BIN:=$(which php)}"

# @description
# an entry point func
#
# @exitcode 0 if update was refused
function main() {
    check_binaries
    echo -e "Feature branch is ${GREEN}$1${NC}"
    
    module_list=$(get_updatable_modules)
    
    if [[ -z "$module_list" ]]; then
        echo -e "${GREEN}Everything is up to date (${module_regex})";
        exit 0;
    else
        echo -e "List of modules for update \n"
        echo -e "$module_list \n"
        
        echo "Do you want to perform update?"
        select yn in "Yes" "No"; do
            case $yn in
                Yes )
                    echo ""
                    for i in $(echo -e "$module_list" | awk '{print $1}'); do
                        update_drupal $i
                    done
                    
                    echo -e "\nAll modules have been updated";
                    echo -e "Don't forget to run $GREEN drush updb $NC command"
                break;;
                No )
                    echo -e "${RED}Cancel update process :(${NC}"
                    exit 1;
                break;;
            esac
        done
    fi
}

# @description
# run the `composer update` command for a specific module
#
# @args
# $1 string The module name in `vendor/module_name` format
function update_drupal() {
    module_name=$1;
    
    $php $composer update $module_name --with-all-dependencies
    git add --all
    git commit -m "$branch_name / update $module_name"
}

# @description
# returns a list of updatable modules
# uses `composer` to fetch this  list
#
# @args
# $1 string A regexp string to find specific modules
#
# @returns
# a list of updatable modules with current/latest version
function get_updatable_modules() {
    $php $composer outdated "${module_regex}" -m 2>&1 |  awk -v red="$RED" \
    -v res="$NC" "/^${module_regex//\/}/ {print \$1, \$2, red, \$4, res}"
}

# @description
# checks if the required executable files exist, e.g php, composer
# if not then exits with error
#
# @exitcode 0 if all files exist
function check_binaries() {
    for i in $c $php; do
        if [ ! -e $i ]; then
            echo "$i doesn't exists"
            exit 2
        fi;
    done
}


main $branch_name