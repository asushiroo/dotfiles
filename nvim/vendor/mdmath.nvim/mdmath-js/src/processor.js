import fs from 'fs';
import mathjax from 'mathjax';
import reader from './reader.js';
import { pngDimensions, pngFitTo, rsvgConvert } from './magick.js';
import { sendNotification, saveFile } from './debug.js';
import { sha256Hash } from './util.js';
import { randomBytes } from 'node:crypto';
import { onExit } from './onexit.js';

// To prevent conflicts with other instances
const DIRECTORY_SUFFIX = randomBytes(3).toString('hex');

// TODO: Portable directory instead of Unix-specific
const IMG_DIR = `/tmp/nvim-mdmath-${DIRECTORY_SUFFIX}`;

/** @typedef {{equation: string, filename: string}} Equation */

/** @type {Equation[]} */
const equations = [];

/** @type {Object.<string, Equation>} */
const equationMap = {};

const svgCache = {};

let internalScale = 1;
let dynamicScale = 1;

let MathJax = undefined;

const INLINE_DESCENDER_EQUATIONS = new Set([
    '\\beta',
    '\\zeta',
    '\\xi',
    '\\phi',
    '\\psi',
]);

const INLINE_DESCENDER_SCALE = 0.84;
const INLINE_DESCENDER_EXPRESSION_SCALE = 0.90;
const INLINE_TALL_EQUATIONS = new Set([
    '\\theta',
    '\\lambda',
    '\\mu',
    '\\chi',
]);
const INLINE_TALL_SCALE = 0.92;
const INLINE_TALL_EXPRESSION_SCALE = 0.95;
const INLINE_BASELINE_REFERENCE = Object.freeze({
    // MathJax default inline italic glyph metrics for a plain symbol like `x`.
    // We keep that centered and offset other inline equations relative to it.
    heightEx: 1.025,
    depthEx: 0.025,
});

function containsAnyCommand(equation, commands) {
    for (const command of commands) {
        if (equation.includes(command))
            return true;
    }

    return false;
}

class MathError extends Error {
    constructor(message) {
        super(message);
        this.name = 'MathError';
    }
}

function mkdirSync(path) {
    try {
        fs.mkdirSync(path, { recursive: true });
    } catch (err) {
        if (err.code !== 'EEXIST')
            throw err;
    }
}

/**
 * @param {string} equation
 * @returns {Promise<{svg: string} | {error: string}>}
 */
async function equationToSVG(equation) {
    if (equation in svgCache)
        return svgCache[equation];

    try {
        const svg = await MathJax.tex2svgPromise(equation);
        const innerSVG = MathJax.startup.adaptor.innerHTML(svg);
        return svgCache[equation] = {
            svg: innerSVG,
            metrics: parseSVGMetrics(innerSVG),
        }
    } catch (err) {
        if (err instanceof MathError) {
            return svgCache[equation] = {
                error: err.message
            }
        } else {

        }

        throw err;
    }
}

function write(identifier, width, height, data) {
    process.stdout.write(`${identifier}:image:${width}:${height}:${data.length}:${data}`);
}

function writeError(identifier, error) {
    process.stdout.write(`${identifier}:error:0:0:${error.length}:${error}`);
}

function parseViewbox(svgString) {
    const viewboxMatch = svgString.match(/viewBox="([^"]+)"/);
    if (!viewboxMatch) return null;

    const [minX, minY, width, height] = viewboxMatch[1].split(' ').map(parseFloat);
    return { minX, minY, width, height };
}

function parseExValue(value) {
    if (!value)
        return null;

    const match = String(value).trim().match(/^(-?\d+(?:\.\d+)?)(?:ex)?$/);
    if (!match)
        return null;

    return Number(match[1]);
}

function parseSVGMetrics(svgString) {
    const heightEx = parseExValue(svgString.match(/\bheight="([^"]+)"/)?.[1]);
    if (!heightEx || heightEx <= 0) {
        return null;
    }

    const verticalAlignEx = parseExValue(svgString.match(/vertical-align:\s*([^;"]+)/)?.[1] ?? '0');
    if (verticalAlignEx !== null) {
        return {
            heightEx,
            depthEx: Math.max(0, -verticalAlignEx),
        };
    }

    const viewbox = parseViewbox(svgString);
    if (!viewbox || !viewbox.height || viewbox.height <= 0) {
        return {
            heightEx,
            depthEx: 0,
        };
    }

    const depthUnits = Math.max(0, viewbox.height + Math.min(0, viewbox.minY));
    return {
        heightEx,
        depthEx: heightEx * (depthUnits / viewbox.height),
    };
}

function computeInlineOffsetY(metrics, pngHeight, targetHeight, equationScale) {
    if (!metrics
        || !Number.isFinite(metrics.heightEx)
        || metrics.heightEx <= 0
        || !Number.isFinite(equationScale)
        || equationScale <= 0) {
        return 0;
    }

    const basePixelsPerEx = pngHeight / (metrics.heightEx * equationScale);
    if (!Number.isFinite(basePixelsPerEx) || basePixelsPerEx <= 0)
        return 0;

    const currentDepthPx = basePixelsPerEx * metrics.depthEx * equationScale;
    const referenceHeightPx = basePixelsPerEx * INLINE_BASELINE_REFERENCE.heightEx;
    const referenceDepthPx = basePixelsPerEx * INLINE_BASELINE_REFERENCE.depthEx;
    const rawOffsetY = currentDepthPx
        - (pngHeight / 2)
        - (referenceDepthPx - (referenceHeightPx / 2));
    const maxOffsetY = Math.max(0, Math.floor((targetHeight - pngHeight) / 2));

    if (maxOffsetY === 0)
        return 0;

    return Math.max(-maxOffsetY, Math.min(maxOffsetY, Math.round(rawOffsetY)));
}

function isDisplayFractionEquation(equation, flags, height) {
    const isDynamic = !!(flags & 1);
    const isCentered = !!(flags & 2);
    if (!isDynamic || isCentered || height <= 1)
        return false;

    const eq = equation.trim();
    return eq.includes('\\frac')
        || eq.includes('\\dfrac')
        || eq.includes('\\tfrac')
        || eq.includes('\\cfrac');
}

/**
  * @param {string} identifier
  * @param {string} equation
*/
async function processEquation(identifier, equation, cWidth, cHeight, width, height, flags, color) {
    if (!equation || equation.trim().length === 0)
        return writeError(identifier, 'Empty equation')

    const normalizedEquation = equation.trim();
    const isInline = !!(flags & 2) && height === 1 && width === 1;
    const needsInlineShrink = isInline && INLINE_DESCENDER_EQUATIONS.has(normalizedEquation);
    const needsInlineTallShrink = isInline && INLINE_TALL_EQUATIONS.has(normalizedEquation);
    const hasDescenderGlyph = isInline && containsAnyCommand(normalizedEquation, INLINE_DESCENDER_EQUATIONS);
    const hasTallGlyph = isInline && containsAnyCommand(normalizedEquation, INLINE_TALL_EQUATIONS);

    let equationScale = 1;
    if (needsInlineShrink) {
        equationScale = INLINE_DESCENDER_SCALE;
    } else if (needsInlineTallShrink) {
        equationScale = INLINE_TALL_SCALE;
    } else if (hasDescenderGlyph) {
        equationScale = INLINE_DESCENDER_EXPRESSION_SCALE;
    } else if (hasTallGlyph) {
        equationScale = INLINE_TALL_EXPRESSION_SCALE;
    }

    const equation_key = `${equation}_${cWidth}*${width}x${cHeight}*${height}_${flags}_${color}_${equationScale}`;
    if (equation_key in equationMap) {
        const equationObj = equationMap[equation_key];
        return write(identifier, equationObj.width, equationObj.height, equationObj.filename);
    }

    let {svg, error, metrics} = await equationToSVG(equation);
    if (!svg)
        return writeError(identifier, error)

    svg = svg
        .replace(/currentColor/g, color)
        .replace(/style="[^"]+"/, '')

    const isDynamic = !!(flags & 1);
    const inlineTargetPixelHeight = isInline
        ? Math.max(1, Math.floor(cHeight * internalScale))
        : null;

    let basePNG;
    let iWidth, iHeight;
    let pngWidth, pngHeight;
    if (isDynamic && isDisplayFractionEquation(equation, flags, height)) {
        const targetHeight = height * cHeight * internalScale;
        basePNG = await rsvgConvert(svg, {height: targetHeight});

        ({width: pngWidth, height: pngHeight} = await pngDimensions(basePNG));
        const newWidth = (pngWidth / internalScale) / cWidth;
        const newHeight = (pngHeight / internalScale) / cHeight;

        width = Math.max(width, Math.ceil(newWidth));
        height = Math.max(height, Math.ceil(newHeight));

        iWidth = width * cWidth * internalScale;
        iHeight = height * cHeight * internalScale;
    } else if (isDynamic) {
        let zoom = 10 * dynamicScale * cHeight * internalScale * equationScale / 96;
        basePNG = await rsvgConvert(svg, {zoom});

        ({width: pngWidth, height: pngHeight} = await pngDimensions(basePNG));

        if (isInline && inlineTargetPixelHeight && pngHeight > inlineTargetPixelHeight) {
            zoom = zoom * (inlineTargetPixelHeight / pngHeight);
            basePNG = await rsvgConvert(svg, {zoom});
            ({width: pngWidth, height: pngHeight} = await pngDimensions(basePNG));
        }

        const newWidth = (pngWidth / internalScale) / cWidth;
        const newHeight = (pngHeight / internalScale) / cHeight;

        // If the image is smaller than the cell, it's better to keep the original size, so
        width = Math.max(width, Math.ceil(newWidth));

        if (isInline) {
            height = 1;
        } else {
            height = Math.max(height, Math.ceil(newHeight));
        }

        iWidth = width * cWidth * internalScale;
        iHeight = height * cHeight * internalScale;
    } else {
        iWidth = width * cWidth * internalScale;
        iHeight = height * cHeight * internalScale;

        basePNG = await rsvgConvert(svg, {width: iWidth, height: iHeight});
    }

    const hash = sha256Hash(equation).slice(0, 7);
    const isCenter = !!(flags & 2);
    const offsetY = isInline
        ? computeInlineOffsetY(metrics, pngHeight, iHeight, equationScale)
        : 0;
    const filename = `${IMG_DIR}/${hash}_${iWidth}x${iHeight}.png`;
    await pngFitTo(basePNG, filename, iWidth, iHeight, {
        center: isCenter,
        offsetY,
    });

    const equationObj = {equation, filename, width, height};
    equations.push(equationObj);
    equationMap[equation_key] = equationObj;

    write(identifier, width, height, filename);
}

function processAll(request) {
    if (request.type === 'request') {
        return processEquation(
            request.identifier,
            request.data,
            request.cellWidth,
            request.cellHeight,
            request.width,
            request.height,
            request.flags,
            request.color
        ).catch((err) => {
            writeError(request.identifier, err.message);
        });
    } else if (request.type === 'dscale') {
        // FIXME: Invalidate cache when scale changes
        dynamicScale = request.scale;
    } else if (request.type === 'iscale') {
        // FIXME: Invalidate cache when scale changes
        internalScale = request.scale;
    }
}

function main() {
    mkdirSync(IMG_DIR);

    onExit(() => {
        equations.forEach(({filename}) => {
            try {
                fs.unlinkSync(filename);
            } catch (err) {}
        });

        try {
            fs.rmdirSync(IMG_DIR);
        } catch (err) {}
    });

    mathjax.init({
        loader: { load: ['input/tex', 'output/svg'] },
        tex: {
            formatError: (_, err) => {
                throw new MathError(err.message);
            }
        }
    }).then((MathJax_) => {
        MathJax = MathJax_;
        reader.listen(processAll);
    }).catch((err) => {
        console.error(err);
        process.exit(1);
    });
}

main();
