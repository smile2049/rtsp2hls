import { spawn } from 'child_process';

interface FFMpegError<T = any> {
  code: number | null;
  data?: T;
}
type FFMpegCallback = (error: FFMpegError | undefined) => void;

export const ffmpeg = (input: string, output: string, callback: FFMpegCallback): void => {
  const process = spawn('ffmpeg', ['-loglevel', 'error', '-re', '-i', input, '-vcodec', 'copy', '-acodec', 'copy', '-f', 'flv', output]);

  process.stderr.on('data', (data) => {
    console.log(`STDERR: ${data}`);
    callback({
      code: 1,
      data,
    });
  });

  process.on('close', (code) => {
    console.log(`Process exited with code ${code}`);
    callback(code === 0 ? undefined : { code });
  });
};
