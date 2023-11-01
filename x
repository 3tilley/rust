#!/bin/sh

# Modern Linux and macOS systems commonly only have a thing called `python3` and
# not `python`, while Windows commonly does not have `python3`, so we cannot
# directly use python in the x.py shebang and have it consistently work. Instead we
# have a shell script to look for a python to run x.py.

set -eux

# syntax check
sh -n "$0"

realpath() {
    local path="$1"
    if [ -L "$path" ]; then
        readlink -f "$path"
    elif [ -d "$path" ]; then
        (cd -P "$path" && pwd)
    else
        echo "$(realpath "$(dirname "$path")")/$(basename "$path")"
    fi
}

xpy=$(dirname "$(realpath "$0")")/x.py

# On Windows, `py -3` sometimes works. We need to try it first because `python3`
# sometimes tries to launch the app store on Windows.

# TODO: Check in python3 is a symlink to the below
# /c/Users/Max/AppData/Local/Microsoft/WindowsApps/python3 -> '/c/Program Files/WindowsApps/Microsoft.DesktopAppInstaller_1.21.2771.0_x64__8wekyb3d8bbwe/AppInstallerPythonRedirector.exe'*
# See: https://github.com/rust-lang/rust/pull/117069
for SEARCH_PYTHON in py python python3 python2; do
    if python=$(command -v $SEARCH_PYTHON) && [ -x "$python" ]; then
        if [ $SEARCH_PYTHON = py ]; then
            extra_arg="-3"
        else
            extra_arg=""
        fi
        exec "$python" $extra_arg "$xpy" "$@"
    fi
done

python=$(bash -c "compgen -c python" | grep '^python[2-3]\.[0-9]\+$' | head -n1)
if ! [ "$python" = "" ]; then
    exec "$python" "$xpy" "$@"
fi

echo "$0: error: did not find python installed" >&2
exit 1
