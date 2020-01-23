#!/bin/sh

# safety subshell to avoid executing anything in case this script is not downloaded properly
(

BOOTSTRAP_HASKELL_VERBOSE = "true"
if [ -n "$1" ] ; then
    GHCUP_INSTALL_BASE_PREFIX="$1"
fi

: "${GHCUP_INSTALL_BASE_PREFIX:=$HOME/goinfre}"

mkdir -p $GHCUP_INSTALL_BASE_PREFIX/.cabal
mkdir -p $GHCUP_INSTALL_BASE_PREFIX/.ghcup
ln -sf $GHCUP_INSTALL_BASE_PREFIX/.cabal $HOME/.cabal
ln -sf $GHCUP_INSTALL_BASE_PREFIX/.ghcup $HOME/.ghcup

die() {
    (>&2 printf "\\033[0;31m%s\\033[0m\\n" "$1")
    exit 2
}

edo()
{
    "$@" || die "\"$*\" failed!"
}

eghcup() {
    if [ -z "${BOOTSTRAP_HASKELL_VERBOSE}" ] ; then
        edo ghcup "$@"
    else
        edo ghcup --verbose "$@"
    fi
}

echo
echo "Welcome to Haskell!"
echo
echo "This will download and install the Glasgow Haskell Compiler (GHC) for "
echo "the Haskell programming language, and the Cabal build tool."
echo
echo "It will add the 'cabal', 'ghc', and 'ghcup' executables to bin directory "
echo "located at: "
echo
echo "  $GHCUP_INSTALL_BASE_PREFIX/haskell/bin"
echo
echo "and create the environment file $GHCUP_INSTALL_BASE_PREFIX/haskell/env"
echo "which you should source in your ~/.bashrc or similar to get the required"
echo "PATH components."
echo

if [ -z "${BOOTSTRAP_HASKELL_NONINTERACTIVE}" ] ; then
    printf "\\033[0;35m%s\\033[0m\\n" "To proceed with the ghcup installation press ENTER, to cancel press ctrl-c."
    printf "\\033[0;35m%s\\033[0m\\n" "Note that this script can be re-run at any given time."
    echo
    # Wait for user input to continue.
    # shellcheck disable=SC2034
    read -r answer </dev/tty
fi

edo mkdir -p "$GHCUP_INSTALL_BASE_PREFIX"/haskell/bin

if command -V "ghcup" >/dev/null 2>&1 ; then
    if [ -z "${BOOTSTRAP_HASKELL_NO_UPGRADE}" ] ; then
        eghcup upgrade
    fi
else
    edo curl --silent https://gitlab.haskell.org/haskell/ghcup/raw/master/ghcup > "$GHCUP_INSTALL_BASE_PREFIX"/haskell/bin/ghcup
    edo chmod +x "$GHCUP_INSTALL_BASE_PREFIX"/haskell/bin/ghcup

	cat <<-EOF > "$GHCUP_INSTALL_BASE_PREFIX"/haskell/env || die "Failed to create env file"
		export PATH="$GHCUP_INSTALL_BASE_PREFIX/.ghcup/bin:$GHCUP_INSTALL_BASE_PREFIX/haskell/bin:\$PATH"
		EOF
	# shellcheck disable=SC1090
    echo "toto"
    edo . "$GHCUP_INSTALL_BASE_PREFIX"/haskell/env
fi

echo
printf "\\033[0;35m%s\\033[0m\\n" "To install and run GHC you need the following dependencies:"
echo "  $(ghcup print-system-reqs)"
echo

if [ -z "${BOOTSTRAP_HASKELL_NONINTERACTIVE}" ] ; then
    printf "\\033[0;35m%s\\033[0m\\n" "You may want to install these now, then press ENTER to proceed"
    printf "\\033[0;35m%s\\033[0m\\n" "or press ctrl-c to abort. Installation may take a while."
    echo

    # Wait for user input to continue.
    # shellcheck disable=SC2034
    read -r answer </dev/tty
fi

eghcup --cache install

eghcup set
eghcup --cache install-cabal

edo cabal new-update

printf "\\033[0;35m%s\\033[0m\\n" ""
printf "\\033[0;35m%s\\033[0m\\n" "Installation done!"
printf "\\033[0;35m%s\\033[0m\\n" ""

if [ -z "${BOOTSTRAP_HASKELL_NONINTERACTIVE}" ] ; then
    echo "In order to run ghc and cabal, you need to adjust your PATH variable."
    echo "You may want to source '$GHCUP_INSTALL_BASE_PREFIX/haskell/env' in your shell"
    echo "configuration to do so (e.g. ~/.bashrc)."

	case $SHELL in
		*/zsh) # login shell is zsh
			GHCUP_PROFILE_FILE="$HOME/.zshrc"
			MY_SHELL="zsh" ;;
		*/bash) # login shell is bash
			if [ -f "$HOME/.bashrc" ] ; then # bashrc is not sourced by default, so assume it isn't if file does not exist
				GHCUP_PROFILE_FILE="$HOME/.bashrc"
			else
				GHCUP_PROFILE_FILE="$HOME/.bash_profile"
			fi

			MY_SHELL="bash" ;;
		*/sh) # login shell is sh, but might be a symlink to bash or zsh
			if [ -n "${BASH}" ] ; then
				if [ -f "$HOME/.bashrc" ] ; then # bashrc is not sourced by default, so assume it isn't if file does not exist
					GHCUP_PROFILE_FILE="$HOME/.bashrc"
				else
					GHCUP_PROFILE_FILE="$HOME/.bash_profile"
				fi

				MY_SHELL="bash"
			elif [ -n "${ZSH_VERSION}" ] ; then
				GHCUP_PROFILE_FILE="$HOME/.zshrc"
				MY_SHELL="zsh"
			else
				exit 0
			fi
			;;
		*) exit 0 ;;
	esac


	printf "\\033[0;35m%s\\033[0m\\n" ""
	printf "\\033[0;35m%s\\033[0m\\n" "Detected ${MY_SHELL} shell on your system..."
	printf "\\033[0;35m%s\\033[0m\\n" "If you want ghcup to automatically add the required PATH variable to \"${GHCUP_PROFILE_FILE}\""
	printf "\\033[0;35m%s\\033[0m\\n" "answer with YES, otherwise with NO and press ENTER."
	printf "\\033[0;35m%s\\033[0m\\n" ""

    while true; do
        read -r next_answer </dev/tty

        case $next_answer in
            [Yy]*)
                echo "[ -f \"$GHCUP_INSTALL_BASE_PREFIX/haskell/env\" ] && source \"$GHCUP_INSTALL_BASE_PREFIX/haskell/env\"" >> "${GHCUP_PROFILE_FILE}"
                printf "\\033[0;35m%s\\033[0m\\n" "OK! ${GHCUP_PROFILE_FILE} has been modified. Restart your terminal for the changes to take effect,"
                printf "\\033[0;35m%s\\033[0m\\n" "or type \"source ${GHCUP_INSTALL_BASE_PREFIX}/haskell/env\" to apply them in your current terminal session."
                exit 0;;
            [Nn]*)
                exit 0;;
            *)
                echo "Please type YES or NO and press enter.";;
        esac
    done
fi
)

# vim: tabstop=4 shiftwidth=4 expandtab

