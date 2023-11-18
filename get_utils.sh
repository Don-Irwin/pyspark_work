#!/bin/bash

# Repository URL and Path for the submodule
REPOSITORY_URL="https://github.com/tuneman7/db_and_excel_utilities"
SUBMODULE_PATH="external/db_and_excel_utilities"

# Clone a repository with submodules
git_clone_with_submodules() {
    local repo_url=$1
    git clone --recurse-submodules $repo_url
}

# Add a submodule to your repository
git_add_submodule() {
    local submodule_url=$1
    local submodule_path=$2
    git submodule add $submodule_url $submodule_path
    git submodule update --init --recursive
}

# Main Function
main() {
    # Call function to add submodule
    git_add_submodule $REPOSITORY_URL $SUBMODULE_PATH

    # Or, call function to clone with submodules (comment out if not needed)
    # git_clone_with_submodules <repository_url_of_the_project_you_want_to_clone>
}

# Execute the main function
main

ln -sfT $SUBMODULE_PATH $(pwd)/libraries
