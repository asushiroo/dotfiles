SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

case "$(uname -s)" in
Darwin*)
	shell_rc_module="zshrc.sh"
	;;
Linux*)
	shell_rc_module="bashrc.sh"
	;;
*)
	shell_rc_module="zshrc.sh"
	;;
esac

rc_modules=(
	"env.sh"
	"$shell_rc_module"
	"utils.sh"
    "alias.sh"
)

load_module() {
	local file="$1"
	local full_path="$SCRIPT_DIR/$file"

	if [ -f "$full_path" ]; then
		# shellcheck source=/dev/null
		source "$full_path"
		# echo "source $full_path success!"
	fi
}

for m in "${rc_modules[@]}"; do
	load_module "$m"
done
