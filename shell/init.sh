
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
rc_modules=(
	"env.sh"
	"zshrc.sh"
)

load_module() {
	local file="$1"
	local full_path="$SCRIPT_DIR/$file"

	if [ -f "$full_path" ]; then
		# shellcheck source=/dev/null
		source "$full_path"
		echo "source $full_path success!"
	fi
}

for m in "${rc_modules[@]}"; do
	load_module "$m"
done
