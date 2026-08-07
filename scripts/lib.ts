/**
 * Helpers shared by this repository's `deno task` scripts.
 *
 * Deliberately dependency-free: the task scripts must run on a bare checkout
 * with no network access, so nothing here imports from JSR or npm.
 *
 * No ANSI colours are emitted (https://no-color.org/).
 */

/** Announce a step. Steps are numbered by the caller when it has a fixed plan. */
export function section(title: string): void {
  console.log(`==> ${title}`);
}

/** Abort the task with a message on stderr and a non-zero exit code. */
export function fail(message: string): never {
  console.error(`error: ${message}`);
  Deno.exit(1);
}

export interface RunOptions {
  args?: string[];
  cwd?: string;
  env?: Record<string, string>;
  /** Return the exit code instead of aborting when the command fails. */
  allowFailure?: boolean;
  /** Capture stdout/stderr instead of streaming them to the terminal. */
  capture?: boolean;
}

export interface RunResult {
  code: number;
  stdout: string;
  stderr: string;
}

/**
 * Run an external command. Fails the task on a non-zero exit unless
 * `allowFailure` is set — "fail fast, fail clearly" is the default.
 */
export async function run(cmd: string, opts: RunOptions = {}): Promise<RunResult> {
  const { args = [], cwd, env, allowFailure = false, capture = false } = opts;
  const command = new Deno.Command(cmd, {
    args,
    cwd,
    env,
    stdout: capture ? "piped" : "inherit",
    stderr: capture ? "piped" : "inherit",
  });

  let output: Deno.CommandOutput;
  try {
    output = await command.output();
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      fail(`${cmd} not found in PATH`);
    }
    throw error;
  }

  const decoder = new TextDecoder();
  const result: RunResult = {
    code: output.code,
    stdout: capture ? decoder.decode(output.stdout) : "",
    stderr: capture ? decoder.decode(output.stderr) : "",
  };

  if (result.code !== 0 && !allowFailure) {
    if (capture) {
      if (result.stdout) console.log(result.stdout);
      if (result.stderr) console.error(result.stderr);
    }
    fail(`${[cmd, ...args].join(" ")} exited with ${result.code}`);
  }
  return result;
}

/** True when the path exists, whatever its type. */
export async function exists(path: string): Promise<boolean> {
  try {
    await Deno.stat(path);
    return true;
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) return false;
    throw error;
  }
}

/** Yield every file under `root` whose name ends with one of `extensions`. */
export async function* walk(root: string, extensions: string[]): AsyncGenerator<string> {
  if (!(await exists(root))) return;
  for await (const entry of Deno.readDir(root)) {
    const path = `${root}/${entry.name}`;
    if (entry.isDirectory) {
      yield* walk(path, extensions);
    } else if (entry.isFile && extensions.some((ext) => entry.name.endsWith(ext))) {
      yield path;
    }
  }
}

/**
 * Report every `path:line` under `roots` matching `pattern`.
 *
 * Replaces the `grep -RInE` the shell scripts used to run: the platform grep is
 * not always GNU grep, and its regex dialects differ enough to change what a
 * gate catches.
 */
export async function scanFiles(
  roots: string[],
  extensions: string[],
  pattern: RegExp,
): Promise<string[]> {
  const hits: string[] = [];
  for (const root of roots) {
    for await (const path of walk(root, extensions)) {
      const lines = (await Deno.readTextFile(path)).split("\n");
      lines.forEach((line, index) => {
        // A fresh lastIndex per line: a /g/ pattern would otherwise skip matches.
        if (new RegExp(pattern.source, pattern.flags.replace("g", "")).test(line)) {
          hits.push(`${path}:${index + 1}: ${line.trim()}`);
        }
      });
    }
  }
  return hits;
}

/**
 * Verify the task scripts themselves: formatting, lint rules and types.
 *
 * `deno run` does not type-check, so without this step a type error in a task
 * script only surfaces when that particular branch happens to execute.
 */
export async function checkTooling(): Promise<void> {
  await run("deno", { args: ["fmt", "--check"] });
  await run("deno", { args: ["lint"] });
  const scripts: string[] = [];
  for await (const path of walk("scripts", [".ts"])) scripts.push(path);
  scripts.sort();
  await run("deno", { args: ["check", ...scripts] });
}
