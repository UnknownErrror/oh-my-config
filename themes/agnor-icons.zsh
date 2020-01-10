() {
	FONT_MODE=${FONT_MODE:-nerdfont} # Default: nerdfont
	typeset -gAH agnor_icons
	local LC_ALL='' LC_CTYPE='en_US.UTF-8' # Set the right locale to protect special characters
	case $FONT_MODE in
		nerdfont*|nf*) # nerd-font patched font required! See https://github.com/ryanoasis/nerd-fonts
			agnor_icons=(
				LEFT_SEGMENT_SEPARATOR         $'\uE0B0' # 
				RIGHT_SEGMENT_SEPARATOR        $'\uE0B2' # 
				LEFT_SEGMENT_END_SEPARATOR     ' '       # Whitespace
				LEFT_SUBSEGMENT_SEPARATOR      $'\uE0B1' # 
				RIGHT_SUBSEGMENT_SEPARATOR     $'\uE0B3' # 
				CARRIAGE_RETURN_ICON           $'\u21B5' # ↵
				ROOT_ICON                      $'\uE614' # 
				SUDO_ICON                      $'\uF09C' # 
				RUBY_ICON                      $'\uF219' # 
				AWS_ICON                       $'\uF270' # 
				AWS_EB_ICON                    $'\uF1BD' # 
				BACKGROUND_JOBS_ICON           $'\uF013' # 
				TEST_ICON                      $'\uF188' # 
				TODO_ICON                      $'\uF133' # 
				BATTERY_ICON                   $'\uF240' # 
				DISK_ICON                      $'\uF0A0' # 
				OK_ICON                        $'\uF00C' # 
				FAIL_ICON                      $'\uF00D' # 
				SYMFONY_ICON                   $'\uE757' # 
				NODE_ICON                      $'\uE617 ' # 
				MULTILINE_FIRST_PROMPT_PREFIX  $'\u256D'$'\u2500'  # ╭─
				MULTILINE_NEWLINE_PROMPT_PREFIX $'\u251C'$'\u2500' # ├─
				MULTILINE_LAST_PROMPT_PREFIX   $'\u2570'$'\u2500'  # ╰─
				HOME_ICON                      $'\uF015' # 
				HOME_SUB_ICON                  $'\uF07C' # 
				FOLDER_ICON                    $'\uF115' # 
				ETC_ICON                       $'\uF013' # 
				NETWORK_ICON                   $'\uF1EB' # 
				LOAD_ICON                      $'\uF080' # 
				SWAP_ICON                      $'\uF464' # 
				RAM_ICON                       $'\uF0E4' # 
				SERVER_ICON                    $'\uF0AE' # 
				VCS_UNTRACKED_ICON             $'\uF059' # 
				VCS_UNSTAGED_ICON              $'\uF06A' # 
				VCS_STAGED_ICON                $'\uF055' # 
				VCS_STASH_ICON                 $'\uF01C' # 
				VCS_INCOMING_CHANGES_ICON      $'\uF01A' # 
				VCS_OUTGOING_CHANGES_ICON      $'\uF01B' # 
				VCS_TAG_ICON                   $'\uF02B' # 
				VCS_BOOKMARK_ICON              $'\uF461' # 
				VCS_COMMIT_ICON                $'\uE729' # 
				VCS_BRANCH_ICON                $'\uF126' # 
				VCS_REMOTE_BRANCH_ICON         $'\uE728' # 
				VCS_GIT_ICON                   $'\uF1D3' # 
				VCS_GIT_GITHUB_ICON            $'\uF113' # 
				VCS_GIT_BITBUCKET_ICON         $'\uE703' # 
				VCS_GIT_GITLAB_ICON            $'\uF296' # 
				VCS_HG_ICON                    $'\uF0C3' # 
				VCS_SVN_ICON                   $'\uE72D' # 
				RUST_ICON                      $'\uE7A8' # 
				PYTHON_ICON                    $'\uE73C' # 
				SWIFT_ICON                     $'\uE755' # 
				GO_ICON                        $'\uE626' # 
				PUBLIC_IP_ICON                 $'\uF0AC' # 
				LOCK_ICON                      $'\uF023' # 
				EXECUTION_TIME_ICON            $'\uF252' # 
				SSH_ICON                       $'\uF489' # 
				VPN_ICON                       '(vpn)'
				KUBERNETES_ICON                $'\u2388' # ⎈
				DROPBOX_ICON                   $'\uF16B' # 
				DATE_ICON                      $'\uF073' # 
				TIME_ICON                      $'\uF017' # 
				JAVA_ICON                      $'\u2615' # ☕︎
				LARAVEL_ICON                   $'\ue73f' # 
				RANGER_ICON                    $'\u2B50' # ⭐
				MIDNIGHT_COMMANDER_ICON        'mc'
				VIM_ICON                       $'\uE62B' # 
				TERRAFORM_ICON                 $'\u1F6E0\u00A0' # 🛠️
				PROXY_ICON                     $'\u2B82' # ⮂
				DOTNET_ICON                    $'\uE77F' # 
				AZURE_ICON                     $'\uFD03' # ﴃ
				DIRENV_ICON                    $'\u25BC' # ▼
				FLUTTER_ICON                   'F'
				GCLOUD_ICON                    $'\uF7B7' # 
			) ;;
		*) # Powerline-patched font required! See https://github.com/Lokaltog/powerline-fonts
			agnor_icons=(
				LEFT_SEGMENT_SEPARATOR         $'\uE0B0' # 
				RIGHT_SEGMENT_SEPARATOR        $'\uE0B2' # 
				LEFT_SEGMENT_END_SEPARATOR     ' '       # Whitespace
				LEFT_SUBSEGMENT_SEPARATOR      $'\uE0B1' # 
				RIGHT_SUBSEGMENT_SEPARATOR     $'\uE0B3' # 
				CARRIAGE_RETURN_ICON           $'\u21B5' # ↵
				ROOT_ICON                      $'\u26A1' # ⚡
				SUDO_ICON                      $'\uE0A2' # 
				RUBY_ICON                      ''
				AWS_ICON                       'AWS:'
				AWS_EB_ICON                    $'\u1F331' # 🌱
				BACKGROUND_JOBS_ICON           $'\u2699' # ⚙
				TEST_ICON                      ''
				TODO_ICON                      $'\u2611' # ☑
				BATTERY_ICON                   $'\u1F50B' # 🔋
				DISK_ICON                      $'hdd '
				OK_ICON                        $'\u2714' # ✔
				FAIL_ICON                      $'\u2718' # ✘
				SYMFONY_ICON                   'SF'
				NODE_ICON                      $'\u2B22' # ⬢
				MULTILINE_FIRST_PROMPT_PREFIX  $'\u256D'$'\u2500'  # ╭─
				MULTILINE_NEWLINE_PROMPT_PREFIX $'\u251C'$'\u2500' # ├─
				MULTILINE_LAST_PROMPT_PREFIX   $'\u2570'$'\u2500'  # ╰─
				HOME_ICON                      ''
				HOME_SUB_ICON                  ''
				FOLDER_ICON                    ''
				ETC_ICON                       $'\u2699' # ⚙
				NETWORK_ICON                   'IP'
				LOAD_ICON                      'L'
				SWAP_ICON                      'SWP'
				RAM_ICON                       'RAM'
				SERVER_ICON                    ''
				VCS_UNTRACKED_ICON             '?'
				VCS_UNSTAGED_ICON              $'\u25CF' # ●
				VCS_STAGED_ICON                $'\u271A' # ✚
				VCS_STASH_ICON                 $'\u235F' # ⍟
				VCS_INCOMING_CHANGES_ICON      $'\u2193' # ↓
				VCS_OUTGOING_CHANGES_ICON      $'\u2191' # ↑
				VCS_TAG_ICON                   ''
				VCS_BOOKMARK_ICON              $'\u263F' # ☿
				VCS_COMMIT_ICON                ''
				VCS_BRANCH_ICON                $'\uE0A0' # 
				VCS_REMOTE_BRANCH_ICON         $'\u2192' # →
				VCS_GIT_ICON                   ''
				VCS_GIT_GITHUB_ICON            ''
				VCS_GIT_BITBUCKET_ICON         ''
				VCS_GIT_GITLAB_ICON            ''
				VCS_HG_ICON                    ''
				VCS_SVN_ICON                   ''
				RUST_ICON                      'Rust'
				PYTHON_ICON                    ''
				SWIFT_ICON                     'Swift'
				GO_ICON                        'Go'
				PUBLIC_IP_ICON                 ''
				LOCK_ICON                      $'\uE0A2' # 
				EXECUTION_TIME_ICON            'Dur'
				SSH_ICON                       '(ssh)'
				VPN_ICON                       '(vpn)'
				KUBERNETES_ICON                $'\u2388' # ⎈
				DROPBOX_ICON                   'Dropbox'
				DATE_ICON                      ''
				TIME_ICON                      ''
				JAVA_ICON                      $'\u2615' # ☕︎
				LARAVEL_ICON                   ''
				MIDNIGHT_COMMANDER_ICON        'mc'
				VIM_ICON                       'vim'
				TERRAFORM_ICON                 $'\u1F6E0\u00A0' # 🛠️
				PROXY_ICON                     $'\u2194' # ↔
				DOTNET_ICON                    '.NET'
				AZURE_ICON                     $'\u2601' # ☁
				DIRENV_ICON                    $'\u25BC' # ▼
				FLUTTER_ICON                   'F'
				GCLOUD_ICON                    'G'
			) ;;
	esac
	function print_icon() { # print_icon <icon_name>
		echo -n "${agnor_icons[$1]}"
	}
}