'use strict';

const fs = require('fs');
const acorn = require('acorn');
const walk = require('acorn-walk');

/**
 * Parses a JS file and extracts function/class declarations and call sites.
 * @param {string} filePath
 * @returns {{ declarations: Array<{type: string, name: string, line: number, col: number}>, callSites: Array<{name: string, line: number, col: number}> } | { error: string, line: number, col: number }}
 */
function extract(filePath) {
  let code;
  try {
    code = fs.readFileSync(filePath, 'utf8');
  } catch (err) {
    return { error: `File read error: ${err.message}`, line: 0, col: 0 };
  }

  let ast;
  try {
    ast = acorn.parse(code, {
      ecmaVersion: 'latest',
      sourceType: 'module',
      locations: true
    });
  } catch (err) {
    try {
      ast = acorn.parse(code, {
        ecmaVersion: 'latest',
        sourceType: 'script',
        locations: true
      });
    } catch (fallbackErr) {
      return {
        error: `Parse error: ${fallbackErr.message}`,
        line: fallbackErr.loc ? fallbackErr.loc.line : 0,
        col: fallbackErr.loc ? fallbackErr.loc.column : 0
      };
    }
  }

  const declarations = [];
  const callSites = [];

  walk.simple(ast, {
    FunctionDeclaration(node) {
      if (node.id && node.id.name) {
        declarations.push({
          type: 'Function',
          name: node.id.name,
          line: node.loc.start.line,
          col: node.loc.start.column
        });
      }
    },
    ClassDeclaration(node) {
      if (node.id && node.id.name) {
        declarations.push({
          type: 'Class',
          name: node.id.name,
          line: node.loc.start.line,
          col: node.loc.start.column
        });
      }
    },
    CallExpression(node) {
      let name = '<anonymous>';
      if (node.callee.type === 'Identifier') {
        name = node.callee.name;
      } else if (node.callee.type === 'MemberExpression') {
        if (node.callee.property && node.callee.property.name) {
          name = node.callee.property.name;
        }
      }
      callSites.push({
        name,
        line: node.loc.start.line,
        col: node.loc.start.column
      });
    }
  });

  return { declarations, callSites };
}

// Allow execution from CLI for testing
if (require.main === module) {
  const file = process.argv[2];
  if (!file) {
    console.error('Usage: node acorn-extract.js <file>');
    process.exit(1);
  }
  const result = extract(file);
  console.log(JSON.stringify(result, null, 2));
  if (result.error) {
    process.exit(1);
  }
}

module.exports = { extract };
