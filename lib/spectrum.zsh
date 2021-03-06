typeset -AHg FX FG BG
FX=(
	reset "%{[00m%}"
	bold "%{[01m%}" no-bold "%{[22m%}"
	italic "%{[03m%}" no-italic "%{[23m%}"
	underline "%{[04m%}" no-underline "%{[24m%}"
	blink "%{[05m%}" no-blink "%{[25m%}"
	reverse "%{[07m%}" no-reverse "%{[27m%}"
)

for color in {000..255}; do
	FG[$color]="%{[38;5;${color}m%}"
	BG[$color]="%{[48;5;${color}m%}"
done

ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris}

function spectrum_ls() { # Show all 256 colors with color number
	for code in {000..255}; do
		print -P -- "$code: %{%F{$code}%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
	done
}
function spectrum_bls() { # Show all 256 colors where the background is set to specific color
	for code in {000..255}; do
		print -P -- "$code: %{%K{$code}%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
	done
}

function spectrum_ls0() { # Show all basic colors with color number
	for code in {000..015}; do
		print -P -- "$code: %{%F{$code}%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
	done
}
function spectrum_bls0() { # Show all basic colors where the background is set to specific color
	for code in {000..015}; do
		print -P -- "$code: %{%K{$code}%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
	done
}