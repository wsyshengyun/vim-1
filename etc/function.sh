# returns for non-interactive shells
[[ $- != *i* ]] && return


#----------------------------------------------------------------------
# quick functions
#----------------------------------------------------------------------
gdbtool () { emacs --eval "(gdb \"gdb --annotate=3 -i=mi $*\")";}

ranger_cd () {
    tempfile="$(mktemp -t tmp.XXXXXXXX)"
    ranger --choosedir="$tempfile" "${@:-$PWD}"
	if [ -n "$tempfile" ] && [ -f "$tempfile" ]; then
		local new_dir=$(cat -- "$tempfile")
		rm -f -- "$tempfile"
		if [ "$new_dir" != "$PWD" ]; then
			cd -- "$new_dir"
		fi
	fi
}


#----------------------------------------------------------------------
# acd_func 1.0.5, 10-nov-2004
#----------------------------------------------------------------------

# petar marinov, http:/geocities.com/h2428, this is public domain
cd_func ()
{
  local x2 the_new_dir adir index
  local -i cnt

  if [[ $1 ==  "--" ]]; then
    dirs -v
    return 0
  fi

  the_new_dir=$1
  [[ -z $1 ]] && the_new_dir=$HOME

  if [[ ${the_new_dir:0:1} == '-' ]]; then
    #
    # Extract dir N from dirs
    index=${the_new_dir:1}
    [[ -z $index ]] && index=1
    adir=$(dirs +$index)
    [[ -z $adir ]] && return 1
    the_new_dir=$adir
  fi

  #
  # '~' has to be substituted by ${HOME}
  [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

  #
  # Now change to the new dir and add to the top of the stack
  pushd "${the_new_dir}" > /dev/null
  [[ $? -ne 0 ]] && return 1
  the_new_dir=$(pwd)

  #
  # Trim down everything beyond 11th entry
  popd -n +11 2>/dev/null 1>/dev/null

  #
  # Remove any other occurence of this dir, skipping the top of the stack
  for ((cnt=1; cnt <= 10; cnt++)); do
    x2=$(dirs +${cnt} 2>/dev/null)
    [[ $? -ne 0 ]] && return 0
    [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
    if [[ "${x2}" == "${the_new_dir}" ]]; then
      popd -n +$cnt 2>/dev/null 1>/dev/null
      cnt=cnt-1
    fi
  done

  return 0
}


if [ -n "$BASH_VERSION" ]; then
	alias cd=cd_func
	alias d='cd_func --'
fi


#----------------------------------------------------------------------
# change title
#----------------------------------------------------------------------
settitle () 
{ 
	[[ "$EMACS" == *term* ]] && return
	echo -ne "\e]2;$@\a\e]1;$@\a"; 
}


#----------------------------------------------------------------------
# zsh skwp theme
#----------------------------------------------------------------------
if [ -n "$ZSH_VERSION" ]; then
	function _prompt_skwp_init {
		# Use extended color pallete if available.
		if [[ $TERM = *256color* || $TERM = *rxvt* ]]; then
			_prompt_skwp_colors=(
			"%F{81}"  # Turquoise
			"%F{166}" # Orange
			"%F{135}" # Purple
			"%F{161}" # Hotpink
			"%F{118}" # Limegreen
			"%F{1}"   # Darkred
			)
		else
			_prompt_skwp_colors=(
			"%F{cyan}"
			"%F{yellow}"
			"%F{magenta}"
			"%F{red}"
			"%F{green}"
			"%F{1}"   # Darkred
			)
		fi

		local reset_color="%F{7}"
		PROMPT="${_prompt_skwp_colors[3]}%n%f@${_prompt_skwp_colors[2]}%m%f ${_prompt_skwp_colors[5]}%~%f %f$ "
		RPROMPT="%{$_prompt_skwp_colors[6]%}%(?..%?)%f"
	}
fi


#----------------------------------------------------------------------
# prompt - normal
#----------------------------------------------------------------------
function _prompt_init_theme {
	if [ -n "$BASH_VERSION" ]; then
		if [[ "$1" == "" ]]; then
			export PS1='\u@\h:\w\$ '
		elif [[ "$1" == "linux" ]]; then
			export PS1='\[\e[32m\]\u@\h\[\e[0m:\[\e[33m\]\w\[\e[0m\]\$ '
		elif [[ "$1" == "debian" ]]; then
			export PS1='\[\e[01;32m\]\u@\h\[\e[00m\]:\[\e[01;34m\]\w\[\e[00m\]\$ '
		elif [[ "$1" == "cygwin" ]]; then
			export PS1='\n\[\e[32m\]\u@\h\[\e[0m \[\e[33m\]\w\[\e[0m\]\n\$ '
		elif [[ "$1" == "msys" ]]; then
			export PS1='\n\[\e[32m\]\u@\h\[\e[0m \[\e[35m\]${MSYSTEM} \[\e[33m\]\w\[\e[0m\]\n\$ '
		elif [[ "$1" == "skwp" ]]; then
			export PS1='\[\e[35m\]\u\[\e[0m\]@\[\e[33m\]\h\[\e[0m:\[\e[32m\]\w\[\e[0m\] \$ '
		elif [[ "$1" == "skwp256" ]]; then
			export PS1='\[\e[38;5;135m\]\u\[\e[0m\]@\[\e[38;5;166m\]\h\[\e[0m \[\e[38;5;118m\]\w\[\e[0m\] \$ '
		elif [[ "$1" == "skwp256-cygwin" ]]; then
			export PS1='\n\[\e[38;5;135m\]\u\[\e[0m\]@\[\e[38;5;166m\]\h\[\e[0m \[\e[38;5;118m\]\w\[\e[0m\]\n\$ '
		elif [[ "$1" == "skwp256-msys" ]]; then
			export PS1='\n\[\e[38;5;135m\]\u\[\e[0m\]@\[\e[38;5;166m\]\h\[\e[0m \[\e[35m\]${MSYSTEM} \[\e[38;5;118m\]\w\[\e[0m\]\n\$ '
		fi
	else
		local NEWLINE=$'\n'
		if [[ "$1" == "" ]]; then
			export PROMPT="%f%n@%m:%~%# "
		elif [[ "$1" == "linux" ]]; then
			export PROMPT="%F{2}%n@%m%f:%F{3}%~%f%# "
		elif [[ "$1" == "debian" ]]; then
			export PROMPT="%F{10}%n@%m%f:%F{12}%~%f%# "
		elif [[ "$1" == "cygwin" ]]; then
			export PROMPT="${NEWLINE}%F{2}%n@%m%f %F{3}%~${NEWLINE}%f%# "
		elif [[ "$1" == "msys" ]]; then
			export PROMPT="${NEWLINE}%F{2}%n@%m%f %F{5}${MSYSTEM} %F{3}%~${NEWLINE}%f%# "
		elif [[ "$1" == "skwp" ]]; then
			export PROMPT="%F{5}%n%f@%F{3}%m%f %F{2}%~%f \$ "
		elif [[ "$1" == "skwp256" ]]; then
			export PROMPT="%F{135}%n%f@%F{166}%m%f %F{118}%~%f \$ "
		elif [[ "$1" == "skwp256-cygwin" ]]; then
			export PROMPT="${NEWLINE}%F{135}%n%f@%F{166}%m%f %F{118}%~%f${NEWLINE}\$ "
		elif [[ "$1" == "skwp256-msys" ]]; then
			export PROMPT="${NEWLINE}%F{135}%n%f@%F{166}%m%f %F{5}${MSYSTEM} %F{118}%~%f${NEWLINE}\$ "
		fi
		RPROMPT="%{$_prompt_skwp_colors[6]%}%(?..%?)%f"
	fi
}


#----------------------------------------------------------------------
# _prompt_title_update
#----------------------------------------------------------------------
function _prompt_title_init
{
	if [ -n "$BASH_VERSION" ]; then
		if [[ "$1" == "" ]]; then
			export PS1="\[\e]0;\w\a\]$PS1"
		else
			export PS1="\[\e]0;\u@\h: \w\a\]$PS1"
		fi
	else
		DISABLE_AUTO_TITLE="false"
	fi
}


#----------------------------------------------------------------------
# auto prompt
#----------------------------------------------------------------------
function _prompt_theme_title
{
	_prompt_init_theme $1
	if [ -n "$SSH_CLIENT" ]; then
		settitle "$(whoami)@$(hostname)"
		if [ -n "$ZSH_VERSION" ]; then
			DISABLE_AUTO_TITLE="true"
		fi
	else
		if [ -n "$BASH_VERSION" ]; then
			_prompt_title_init "yes"
		else
			DISABLE_AUTO_TITLE="false"
		fi
	fi
}


#----------------------------------------------------------------------
# utility
#----------------------------------------------------------------------

# Easy extract
function q-extract
{
	if [ -f $1 ] ; then
		case $1 in
		*.tar.bz2)   tar -xvjf $1    ;;
		*.tar.gz)    tar -xvzf $1    ;;
		*.tar.xz)    tar -xvJf $1    ;;
		*.bz2)       bunzip2 $1     ;;
		*.rar)       rar x $1       ;;
		*.gz)        gunzip $1      ;;
		*.tar)       tar -xvf $1     ;;
		*.tbz2)      tar -xvjf $1    ;;
		*.tgz)       tar -xvzf $1    ;;
		*.zip)       unzip $1       ;;
		*.Z)         uncompress $1  ;;
		*.7z)        7z x $1        ;;
		*)           echo "don't know how to extract '$1'..." ;;
		esac
	else
		echo "'$1' is not a valid file!"
	fi
}

# easy compress - archive wrapper
function q-compress
{
	if [ -n "$1" ] ; then
		FILE=$1
		case $FILE in
		*.tar) shift && tar -cf $FILE $* ;;
		*.tar.bz2) shift && tar -cjf $FILE $* ;;
		*.tar.xz) shift && tar -cJf $FILE $* ;;
		*.tar.gz) shift && tar -czf $FILE $* ;;
		*.tgz) shift && tar -czf $FILE $* ;;
		*.zip) shift && zip $FILE $* ;;
		*.rar) shift && rar $FILE $* ;;
		esac
	else
		echo "usage: compress <foo.tar.gz> ./foo ./bar"
	fi
}

# get current host related info
function q-sysinfo
{
	echo -e "\nYou are logged on ${RED}$HOST"
	echo -e "\nAdditionnal information:$NC " ; uname -a
	echo -e "\n${RED}Users logged on:$NC " ; w -h
	echo -e "\n${RED}Current date :$NC " ; date
	echo -e "\n${RED}Machine stats :$NC " ; uptime
	echo -e "\n${RED}Memory stats :$NC " ; free
	echo -e "\n${RED}Public IP Address :$NC" ; q-myip
	echo -e "\n${RED}Local IP Address :$NC" ; q-ips
}

# get public IP
function q-myip
{
	if [ -x "$(which curl)" ]; then
		curl ifconfig.co
	elif [ -x "$(which wget)" ]; then
		wget -qO- ifconfig.co
	fi
}

# get all IPs
function q-ips
{
	case $OS in
	Darwin|*BSD)
		local ip=$(ifconfig  | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}')
		;;
	*)
		local ip=$(hostname --all-ip-addresses | tr " " "\n" | grep -v "0.0.0.0" | grep -v "127.0.0.1")
		;;
	esac

	echo "${ip}"
}



# lazy gcc, default outfile: filename_prefix.out, eg: hello.c -> hello.out
function q-gcc
{
	gcc -o ${1%.*}{.out,.${1##*.}} $2 $3 $4 $5
}



# Display ANSI colours. Found this on the interwebs, credited
# to "HH".
function q-ansicolors 
{
	esc="\033["
	echo -e "\t  40\t   41\t   42\t    43\t      44       45\t46\t 47"
	for fore in 30 31 32 33 34 35 36 37; do
		line1="$fore  "
		line2="    "
		for back in 40 41 42 43 44 45 46 47; do
			line1="${line1}${esc}${back};${fore}m Normal  ${esc}0m"
			line2="${line2}${esc}${back};${fore};1m Bold    ${esc}0m"
		done
		echo -e "$line1\n$line2"
	done

	echo ""
	echo "# Example:"
	echo "#"
	echo "# Type a Blinkin TJEENARE in Swedens colours (Yellow on Blue)"
	echo "#"
	echo "#           ESC"
	echo "#            |  CD"
	echo "#            |  | CD2"
	echo "#            |  | | FG"
	echo "#            |  | | |  BG + m"
	echo "#            |  | | |  |         END-CD"
	echo "#            |  | | |  |            |"
	echo "# echo -e '\033[1;5;33;44mTJEENARE\033[0m'"
	echo "#"
	echo "# Sedika Signing off for now ;->"
}


# Start an HTTP server from a directory, optionally specifying the port (by paulirish)
function q-server () {
	local port="${1:-8000}"
	exist open && open "http://localhost:${port}/"
	# Set the default Content-Type to `text/plain` instead of `application/octet-stream`
	# And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
	python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# whois a domain or a URL (by paulirish)
function q-whois () {
	local domain=$(echo "$1" | awk -F/ '{print $3}') # get domain from URL
	if [ -z $domain ] ; then
		domain=$1
	fi
	echo "Getting whois record for: $domain …"

	# avoid recursion
                    # this is the best whois server
                                                   # strip extra fluff
    /usr/bin/whois -h whois.internic.net $domain | sed '/NOTICE:/q'
}


function q-weather {
	local city="${1:-guangzhou}"
	if [ -x "$(which wget)" ]; then
		wget -qO- "wttr.in/~${city}"
	elif [ -x "$(which curl)" ]; then
		curl "wttr.in/~${city}"
	fi
}


#----------------------------------------------------------------------
# advance keymap
#----------------------------------------------------------------------

# default bash key binding
if [ -n "$BASH_VERSION" ]; then
	bind '"\eu":"ranger_cd\n"'
	bind '"\eOS":"vim "'
	bind '"\e[15~":"\$(__fzf_cd__)\n"'
elif [ -n "$ZSH_VERSION" ]; then
	bindkey -s '\eOS' 'vim '
	bindkey -s '\eu' 'ranger_cd\n'
	bindkey '\e[15~' fzf-cd-widget
fi


#----------------------------------------------------------------------
# Logout
#----------------------------------------------------------------------

# Function to run upon exit of shell.
function _exit() {
	echo "Logged out actively at `date`"
}

# run function on logout
trap _exit EXIT

