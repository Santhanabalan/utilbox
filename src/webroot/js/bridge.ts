import { exec as ksuExec } from 'kernelsu';

export const MODDIR = '/data/adb/modules/utilbox';
const EXEC_TIMEOUT_MS = 15000;

export interface ExecResult {
  errno: number;
  stdout: string;
  stderr: string;
}

export function hasBridge(): boolean {
  return typeof (window as { ksu?: unknown }).ksu !== 'undefined';
}

export async function exec(command: string): Promise<ExecResult> {
  if (!hasBridge()) throw new Error('Open UtilBox from the KernelSU or APatch manager.');
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error('Command timed out')), EXEC_TIMEOUT_MS);
  });
  try {
    return await Promise.race([ksuExec(command) as Promise<ExecResult>, timeout]);
  } finally {
    clearTimeout(timer);
  }
}
