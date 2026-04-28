local M = {}

local function is_svg_xml(path)
	local file = io.open(path, "rb")
	if not file then
		return false
	end

	local chunk = file:read(1024) or ""
	file:close()

	return chunk:find("<svg", 1, true) ~= nil
end

local function convert_svg_to_png(path, output_path)
	local out_path = output_path or path:gsub("%.[^.]+$", ".png")
	if out_path == path then
		out_path = path .. ".png"
	end

	local result = vim.system({ "rsvg-convert", path, "-o", out_path }, { text = true }):wait()
	if result.code ~= 0 then
		error(result.stderr ~= "" and result.stderr or "Failed to convert SVG to PNG with rsvg-convert")
	end

	return out_path
end

function M.apply()
	if vim.fn.executable("rsvg-convert") ~= 1 then
		return
	end

	local ok, processor = pcall(require, "image/processors/magick_cli")
	if not ok or processor._rsvg_convert_to_png_patched then
		return
	end

	local original_convert_to_png = processor.convert_to_png
	processor.convert_to_png = function(path, output_path)
		local format = processor.get_format(path)
		if format == "svg" or (format == "xml" and is_svg_xml(path)) then
			return convert_svg_to_png(path, output_path)
		end

		return original_convert_to_png(path, output_path)
	end

	processor._rsvg_convert_to_png_patched = true
end

return M
